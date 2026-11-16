<template>
  <div class="page">
    <SectNav active="quest" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 阁名 + 背景 -->
    <header class="hero">
      <span class="hero-seal">令</span>
      <div>
        <h1>任务阁</h1>
        <p class="hero-desc">宗门悬赏赏贡献灵石，个人悬赏赠奇珍异宝 —— 接了令，就要交差</p>
      </div>
      <button type="button" class="publish-btn" @click="openPublish">＋ 发布悬赏</button>
    </header>

    <!-- 悬赏来源：宗门 / 个人 -->
    <section class="tabs-wrap">
      <div class="type-tabs">
        <button
          v-for="t in typeTabs"
          :key="t.id"
          type="button"
          class="type-tab"
          :class="[{ active: activeType === t.id }, 'type-' + t.id]"
          @click="switchType(t.id)"
        >
          <span class="type-mark">{{ t.icon }}</span>{{ t.name }}
          <small class="tab-count">{{ typeCounts[t.id] ?? 0 }}</small>
        </button>
      </div>

      <!-- 分类分堂 -->
      <div class="tabs">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          type="button"
          class="tab"
          :class="{ active: activeTab === tab.id }"
          @click="switchTab(tab.id)"
        >
          {{ tab.name }}
          <small v-if="counts[tab.id]" class="tab-count">{{ counts[tab.id] }}</small>
        </button>
      </div>

      <!-- 排序 -->
      <div class="sort-bar">
        <button
          v-for="s in sortOptions"
          :key="s.value"
          type="button"
          class="sort-btn"
          :class="{ active: sort === s.value }"
          @click="changeSort(s.value)"
        >{{ s.label }}</button>
      </div>

      <p v-if="error" class="empty">{{ error }}</p>
      <p v-else-if="!loading && !list.length" class="empty">阁中暂无悬赏，且待{{ activeType === 'personal' ? '道友' : '宗门' }}发令</p>

      <ul v-else class="list">
        <li v-for="item in list" :key="item.id" class="row">
          <span class="row-icon">{{ item.icon || '🗡️' }}</span>
          <div class="row-main">
            <h3>
              {{ item.title }}
              <small class="difficulty" :class="difficultyClass(item.difficulty)">{{ item.difficulty }}</small>
              <small v-if="item.questType === 'personal'" class="publisher">个人 · {{ item.publisher }}</small>
            </h3>
            <p>{{ item.description }}</p>
            <div class="reward-line">
              <span v-if="item.rewardContribution" class="rw rw-c">贡献值 +{{ item.rewardContribution }}</span>
              <span v-if="item.rewardStones" class="rw rw-s">灵石 +{{ item.rewardStones }}</span>
              <span v-if="item.rewardItem" class="rw rw-i">🎁 {{ item.rewardItem }}</span>
              <span class="rw rw-gate">修为需 {{ item.minRealm }} 以上 · 名额 {{ item.currentAcceptors || 0 }}/{{ item.maxAccept }}</span>
            </div>
          </div>
          <div class="row-side">
            <span class="row-meta">{{ item.category }} · 累计 {{ item.acceptCount }} 人接令</span>
            <span class="reward">{{ rewardBrief(item) }}</span>
            <button
              type="button"
              class="accept-btn"
              :class="{ ongoing: isOngoing(item.id), disabled: acceptState(item) !== 'ok' }"
              :disabled="busyId === item.id || (acceptState(item) !== 'ok' && !isOngoing(item.id))"
              :title="acceptTip(item)"
              @click="acceptState(item) === 'ok' && doAccept(item)"
            >{{ acceptText(item) }}</button>
          </div>
        </li>
      </ul>

      <div v-if="pages > 1" class="pager">
        <button type="button" class="pager-btn" :disabled="page <= 1" @click="gotoPage(page - 1)">上一页</button>
        <span class="pager-info">第 {{ page }} / {{ pages }} 页</span>
        <button type="button" class="pager-btn" :disabled="page >= pages" @click="gotoPage(page + 1)">下一页</button>
      </div>
    </section>

    <!-- ===== 我的任务牌（洞府联动） ===== -->
    <section class="tabs-wrap my-wrap">
      <div class="my-head">
        <h2>我的任务牌</h2>
        <small class="my-hint">进行中 {{ questActive }} · 已完成 {{ questDone }} · 累计贡献值 {{ contributionTotal }} · 灵石 {{ stonesTotal }}（同步洞府）</small>
        <button type="button" class="my-refresh" @click="loadMine">刷新</button>
      </div>

      <p v-if="!myList.length" class="empty">
        尚未接取任何任务 —— 从上面的悬赏里挑一枚令牌吧
      </p>
      <ul v-else class="list my-list">
        <li v-for="m in myList" :key="m.id" class="row" :class="{ done: m.status === 1, dropped: m.status === 2 }">
          <span class="row-icon">{{ m.icon || '🗡️' }}</span>
          <div class="row-main">
            <h3>
              {{ m.title }}
              <small v-if="m.difficulty" class="difficulty" :class="difficultyClass(m.difficulty)">{{ m.difficulty }}</small>
              <small v-if="m.questType === 'personal'" class="publisher">个人 · {{ m.publisher }}</small>
            </h3>
            <p>
              接令 {{ fmtTime(m.createTime) }}
              <template v-if="m.finishTime"> · 交差 {{ fmtTime(m.finishTime) }}</template>
            </p>
          </div>
          <div class="row-side">
            <span class="status-pill" :class="'s-' + m.status">{{ m.statusText }}</span>
            <span class="reward">{{ rewardBrief(m, m.status === 1) }}</span>
            <span v-if="m.status === 0" class="my-actions">
              <button type="button" class="mini-btn primary" :disabled="busyId === 'r' + m.id" @click="doFinish(m)">交 差</button>
              <button type="button" class="mini-btn" :disabled="busyId === 'r' + m.id" @click="doAbandon(m)">放 弃</button>
            </span>
          </div>
        </li>
      </ul>
    </section>

    <footer class="page-foot">© 2026 逆天魔宗 · 任务阁 · 一令既出，驷马难追</footer>

    <!-- ===== 发布个人悬赏弹窗 ===== -->
    <div v-if="publishing" class="mask" @click.self="publishing = false">
      <div class="publish-panel">
        <button class="publish-close" type="button" @click="publishing = false">✕</button>
        <h2 class="publish-title">张榜 · 发布个人悬赏</h2>
        <p class="publish-sub">奖励自定（天才地宝、法宝、手作皆可），强度随难度与修为门槛而定</p>

        <div class="form-grid">
          <label class="field field-wide">
            <span>任务名 *</span>
            <input v-model="form.title" maxlength="100" placeholder="一句话说清要办什么事" />
          </label>
          <label class="field field-wide">
            <span>任务详情</span>
            <textarea v-model="form.description" maxlength="500" rows="3" placeholder="时间、地点、要求、注意事项……"></textarea>
          </label>
          <label class="field">
            <span>分类</span>
            <select v-model="form.category">
              <option v-for="c in CATEGORIES" :key="c" :value="c">{{ c }}</option>
            </select>
          </label>
          <label class="field">
            <span>难度（决定任务强度）</span>
            <select v-model="form.difficulty">
              <option v-for="d in DIFFICULTIES" :key="d" :value="d">{{ d }}</option>
            </select>
          </label>
          <label class="field">
            <span>修为门槛</span>
            <select v-model="form.minRealm">
              <option v-for="r in REALMS" :key="r" :value="r">{{ r }} 以上</option>
            </select>
          </label>
          <label class="field">
            <span>接取名额（1-99）</span>
            <input v-model.number="form.maxAccept" type="number" min="1" max="99" />
          </label>
          <label class="field field-wide">
            <span>奖励说明 *（天才地宝 / 法宝 / 其它）</span>
            <input v-model="form.rewardItem" maxlength="100" placeholder="如：百年血参两株、上古剑丸、护身符一枚……" />
          </label>
          <label class="field">
            <span>令牌图标</span>
            <input v-model="form.icon" maxlength="4" placeholder="🗡️" />
          </label>
        </div>
        <div class="form-actions">
          <button class="btn-ghost" type="button" @click="publishing = false">取 消</button>
          <button class="btn-primary" type="button" :disabled="saving" @click="doPublish">
            {{ saving ? '张榜中…' : '张 榜' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import {
  abandonQuest,
  acceptQuest,
  fetchMyQuests,
  fetchProfileRealm,
  fetchQuestList,
  fetchQuestSummary,
  fetchQuestTypes,
  publishQuest
} from '../api/quest'

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const REALMS = ['炼气', '筑基', '金丹', '元婴', '化神', '炼虚', '合体', '大乘', '渡劫', '魔尊']
const DIFFICULTIES = ['简单', '普通', '困难', '地狱']
const CATEGORIES = ['斩妖', '夺宝', '护送', '炼丹', '寻物', '戒律', '其它']

const typeTabs = [
  { id: '', name: '全部悬赏', icon: '📢' },
  { id: 'sect', name: '宗门悬赏', icon: '🏯' },
  { id: 'personal', name: '个人悬赏', icon: '🧙' }
]
const activeType = ref('')
const typeCounts = ref({})

const tabs = ref([{ id: '', name: '全部分堂' }])
const activeTab = ref('')
const counts = ref({})
const sort = ref('hot')
const sortOptions = [
  { value: 'hot', label: '最热' },
  { value: 'new', label: '最新' },
  { value: 'reward', label: '奖励' },
  { value: 'hard', label: '难度' }
]

const loading = ref(false)
const error = ref('')
const list = ref([])
const page = ref(1)
const pageSize = 8
const pages = ref(0)

// 我的境界（判断能否接取）
const myRealmIdx = ref(0)

// 我的任务牌（与洞府联动）
const myList = ref([])
const questActive = ref(0)
const questDone = ref(0)
const contributionTotal = ref(0)
const stonesTotal = ref(0)

const busyId = ref(null)

// 发布个人悬赏
const publishing = ref(false)
const saving = ref(false)
const form = ref(defaultForm())

function defaultForm() {
  return {
    title: '', description: '', category: '寻物', difficulty: '普通',
    minRealm: '炼气', maxAccept: 1, rewardItem: '', icon: '🗡️'
  }
}

/** 进行中任务 id 集合：列表上的「接取」按钮据此变为「任务在手」 */
const ongoingIds = computed(() =>
  new Set(myList.value.filter(m => m.status === 0).map(m => m.questId)))

function isOngoing(questId) {
  return ongoingIds.value.has(questId)
}

/** 接取资格：ok / full（名额已满）/ realm（修为不足） */
function acceptState(item) {
  if (isOngoing(item.id)) return 'ok'
  if (item.full) return 'full'
  const need = REALMS.indexOf(item.minRealm || '炼气')
  if (need > myRealmIdx.value) return 'realm'
  return 'ok'
}

function acceptTip(item) {
  const s = acceptState(item)
  if (s === 'full') return `名额已满（${item.currentAcceptors || 0}/${item.maxAccept}）`
  if (s === 'realm') return `修为不足：需 ${item.minRealm} 以上`
  return ''
}

function acceptText(item) {
  if (isOngoing(item.id)) return '任务在手'
  if (busyId.value === item.id) return '接令中…'
  const s = acceptState(item)
  if (s === 'full') return '名额已满'
  if (s === 'realm') return '修为不足'
  return '接 取'
}

/** 一句话概括奖励 */
function rewardBrief(item, earned = false) {
  const parts = []
  const c = earned ? item.rewardContribution : item.rewardContribution
  const s = earned ? item.rewardStones : item.rewardStones
  if (item.questType === 'personal') {
    if (earned && item.rewardItem) return item.rewardItem
    return item.questItem || item.rewardItem || ''
  }
  if (c) parts.push(`贡献值 ${c}`)
  if (s) parts.push(`灵石 ${s}`)
  return parts.join(' · ')
}

onMounted(() => {
  load()
  loadMine()
  loadRealm()
})

async function loadRealm() {
  try {
    const data = await fetchProfileRealm(props.username)
    const realm = data?.profile?.realm || '炼气'
    myRealmIdx.value = Math.max(0, REALMS.indexOf(realm))
  } catch {
    myRealmIdx.value = 0
  }
}

async function load(toPage = 1) {
  loading.value = true
  error.value = ''
  try {
    const [data, summary, types] = await Promise.all([
      fetchQuestList({
        type: activeType.value || undefined,
        category: activeTab.value || undefined,
        sort: sort.value,
        page: toPage,
        size: pageSize
      }),
      fetchQuestSummary(activeType.value || undefined).catch(() => ({})),
      fetchQuestTypes().catch(() => ({}))
    ])
    list.value = data.list || []
    pages.value = data.pages || 0
    page.value = data.page || toPage
    counts.value = summary || {}
    typeCounts.value = types || {}
    // 分类 tab：全部 + 各分类（带计数）
    const catTabs = Object.entries(summary || {}).map(([name, count]) => ({ id: name, name, count }))
    tabs.value = [{ id: '', name: '全部分堂' }, ...catTabs]
  } catch (e) {
    error.value = e.message || '任务阁加载失败'
  } finally {
    loading.value = false
  }
}

/** 我的任务牌：后端返回记录列表，统计就地汇总（与洞府 stats 同口径） */
async function loadMine() {
  try {
    const data = await fetchMyQuests(props.username)
    myList.value = data || []
    const done = myList.value.filter(m => m.status === 1)
    questActive.value = myList.value.filter(m => m.status === 0).length
    questDone.value = done.length
    contributionTotal.value = done.reduce((sum, m) => sum + (m.rewardContribution || 0), 0)
    stonesTotal.value = done.reduce((sum, m) => sum + (m.rewardStones || 0), 0)
  } catch (e) {
    showToast(e.message || '任务牌加载失败')
  }
}

function switchType(id) {
  if (activeType.value === id) return
  activeType.value = id
  load(1)
}

function switchTab(id) {
  if (activeTab.value === id) return
  activeTab.value = id
  load(1)
}

function changeSort(s) {
  if (sort.value === s) return
  sort.value = s
  load(1)
}

function gotoPage(p) {
  if (p < 1 || p > pages.value || p === page.value) return
  load(p)
}

function openPublish() {
  form.value = defaultForm()
  publishing.value = true
}

async function doPublish() {
  if (saving.value) return
  if (!form.value.title.trim()) {
    showToast('任务名不能为空')
    return
  }
  if (!form.value.rewardItem.trim()) {
    showToast('个人悬赏必须写明奖励')
    return
  }
  saving.value = true
  try {
    await publishQuest({ username: props.username, ...form.value })
    showToast('悬赏已张榜，等待道友揭榜')
    publishing.value = false
    activeType.value = 'personal'
    activeTab.value = ''
    await load(1)
    await loadMine()
  } catch (e) {
    showToast(e.message || '张榜失败')
  } finally {
    saving.value = false
  }
}

async function doAccept(item) {
  if (busyId.value) return
  busyId.value = item.id
  try {
    await acceptQuest(props.username, item.id)
    showToast(`已接令「${item.title}」`)
    await Promise.all([loadMine(), load(page.value)])
  } catch (e) {
    showToast(e.message || '接令失败')
    await loadMine()
    await load(page.value)
  } finally {
    busyId.value = null
  }
}

async function doFinish(m) {
  if (busyId.value) return
  busyId.value = 'r' + m.id
  try {
    const res = await finishQuest(props.username, m.questId)
    const got = res?.rewardItem
      ? `「${res.rewardItem}」已到手`
      : `贡献值 ${res?.rewardContribution ?? 0}${res?.rewardStones ? ` · 灵石 ${res.rewardStones}` : ''} 已入洞府账册`
    showToast(`交差成功！${got}`)
    await Promise.all([loadMine(), load(page.value)])
  } catch (e) {
    showToast(e.message || '交差失败')
  } finally {
    busyId.value = null
  }
}

async function doAbandon(m) {
  if (busyId.value) return
  busyId.value = 'r' + m.id
  try {
    await abandonQuest(props.username, m.questId)
    showToast('已放弃此任务，功过不记')
    await Promise.all([loadMine(), load(page.value)])
  } catch (e) {
    showToast(e.message || '放弃失败')
  } finally {
    busyId.value = null
  }
}

function difficultyClass(d) {
  switch (d) {
    case '地狱': return 'd-hell'
    case '困难': return 'd-hard'
    case '普通': return 'd-normal'
    default: return 'd-easy'
  }
}

function fmtTime(s) {
  return s ? String(s).slice(0, 16).replace('T', ' ') : ''
}
</script>

<style scoped>
.page {
  position: relative;
  width: 100%;
  max-width: 1320px;
  margin: 0 auto;
  /* 半透明面板：与宗门各堂一致，全屏背景透出 */
  background: rgba(8, 5, 12, .20);
  border: 1px solid rgba(196, 154, 92, .18);
  border-radius: 22px;
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .06),
    0 24px 60px rgba(0, 0, 0, .50),
    0 0 50px rgba(200, 16, 46, .12);
}

/* ===== 阁名 ===== */
.hero {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 34px 32px 22px;
}

.hero-seal {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 30px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 2px solid var(--gold);
  box-shadow: 0 4px 18px rgba(200, 16, 46, .5), inset 0 0 10px rgba(0, 0, 0, .35);
  transform: rotate(-6deg);
  flex-shrink: 0;
}

.hero h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 26px;
  font-weight: 700;
  letter-spacing: 4px;
  color: #f3e8d6;
  text-shadow: 0 2px 18px rgba(200, 16, 46, .45);
  margin: 0;
}

.hero-desc {
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(212, 175, 55, .75);
  margin: 6px 0 0;
}

.publish-btn {
  margin-left: auto;
  align-self: flex-start;
  padding: 8px 16px;
  border: 1px solid var(--gold);
  border-radius: 9px;
  background: linear-gradient(135deg, rgba(140, 15, 29, .85), rgba(200, 16, 46, .65));
  color: #f7e9c4;
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  box-shadow: 0 4px 14px rgba(200, 16, 46, .35);
  flex-shrink: 0;
  transition: transform .18s;
}

.publish-btn:hover { transform: translateY(-1px); }

/* ===== 悬赏来源 tab ===== */
.type-tabs { display: flex; gap: 10px; margin-bottom: 14px; }

.type-tab {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 22px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(12, 8, 18, .72);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 15px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s, box-shadow .18s;
}

.type-tab:hover { color: var(--gold-soft); border-color: var(--gold); }

.type-mark { font-size: 16px; }

.type-tab.active {
  color: #f7e9c4;
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .7), rgba(200, 16, 46, .5));
  box-shadow: 0 0 14px rgba(200, 16, 46, .3);
}

.type-tab.type-personal.active {
  background: linear-gradient(135deg, rgba(76, 29, 149, .55), rgba(140, 15, 29, .5));
}

/* ===== 分类 tab ===== */
.tabs-wrap { padding: 0 32px 24px; }

.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 14px;
}

.tab {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 16px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(12, 8, 18, .72);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s;
}

.tab:hover { color: var(--gold-soft); border-color: var(--gold); }

.tab.active {
  color: #f7e9c4;
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .7), rgba(200, 16, 46, .5));
}

.tab-count {
  font-size: 11px;
  color: var(--text-dim);
  letter-spacing: 0;
}

/* ===== 排序 ===== */
.sort-bar { display: flex; gap: 6px; margin-bottom: 12px; }

.sort-btn {
  padding: 4px 14px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(12, 8, 18, .5);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s;
}

.sort-btn:hover { color: var(--gold-soft); border-color: var(--gold); }

.sort-btn.active {
  color: #f7e9c4;
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .7), rgba(200, 16, 46, .5));
  box-shadow: 0 0 12px rgba(200, 16, 46, .3);
}

/* ===== 任务列表 ===== */
.empty {
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
  padding: 22px 0;
}

.list {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
}

.row {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 16px;
  background: rgba(10, 7, 15, .78);
  transition: background .15s;
}

.row + .row { border-top: 1px solid var(--border); }
.row:hover { background: rgba(28, 18, 36, .65); }

.row.done { opacity: .62; }
.row.dropped { opacity: .42; }

.row-icon { font-size: 20px; line-height: 1; flex-shrink: 0; }

.row-main { flex: 1; min-width: 0; }

.row-main h3 {
  font-size: 15px;
  color: #f3e8d6;
  letter-spacing: 1px;
  margin: 0 0 3px;
}

.row-main p {
  font-size: 13px;
  line-height: 1.6;
  color: var(--text-soft);
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.difficulty {
  display: inline-block;
  margin-left: 8px;
  padding: 1px 8px;
  font-size: 11px;
  border-radius: 999px;
  border: 1px solid rgba(212, 175, 55, .4);
  vertical-align: middle;
}

.d-easy { color: #9fd0a8; border-color: rgba(159, 208, 168, .45); }
.d-normal { color: #e2c46e; border-color: rgba(226, 196, 110, .45); }
.d-hard { color: #e23a4e; border-color: rgba(226, 58, 78, .5); }
.d-hell {
  color: #ffd76a;
  background: linear-gradient(135deg, rgba(140, 15, 29, .8), rgba(200, 16, 46, .6));
  border-color: var(--gold);
  box-shadow: 0 0 10px rgba(200, 16, 46, .4);
}

.publisher {
  margin-left: 8px;
  padding: 1px 8px;
  font-size: 11px;
  border-radius: 999px;
  color: #c9b6ff;
  border: 1px solid rgba(180, 138, 255, .4);
  vertical-align: middle;
}

/* 奖励行：贡献值 / 灵石 / 物品 / 门槛名额 */
.reward-line {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin-top: 5px;
}

.rw {
  padding: 1px 9px;
  font-size: 12px;
  border-radius: 999px;
  letter-spacing: 1px;
}

.rw-c {
  color: #e8c66a;
  background: rgba(212, 175, 55, .10);
  border: 1px solid rgba(212, 175, 55, .35);
}

.rw-s {
  color: #9fd0ff;
  background: rgba(159, 208, 255, .08);
  border: 1px solid rgba(159, 208, 255, .30);
}

.rw-i {
  color: #ffd76a;
  background: linear-gradient(135deg, rgba(140, 15, 29, .55), rgba(200, 16, 46, .35));
  border: 1px solid rgba(212, 175, 55, .45);
}

.rw-gate {
  color: var(--text-dim);
  background: rgba(12, 8, 18, .5);
  border: 1px dashed var(--border-strong);
}

.row-side {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  flex-shrink: 0;
}

.row-meta {
  font-size: 12px;
  color: rgba(212, 175, 55, .6);
  letter-spacing: 1px;
}

.reward {
  font-size: 13px;
  font-family: "STKaiti", "KaiTi", serif;
  color: #f3e8d6;
  text-shadow: 0 0 12px rgba(212, 175, 55, .35);
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.accept-btn {
  padding: 6px 16px;
  border: 1px solid var(--gold);
  border-radius: 9px;
  background: linear-gradient(135deg, rgba(140, 15, 29, .85), rgba(200, 16, 46, .65));
  color: #f7e9c4;
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  box-shadow: 0 4px 14px rgba(200, 16, 46, .35);
  transition: opacity .18s, transform .18s;
  min-width: 92px;
}

.accept-btn:hover:not(:disabled):not(.ongoing) { transform: translateY(-1px); }

.accept-btn.ongoing,
.accept-btn.disabled {
  background: rgba(12, 8, 18, .6);
  border-color: var(--border-strong);
  color: var(--text-dim);
  cursor: not-allowed;
  box-shadow: none;
}

.accept-btn:disabled { opacity: .6; }

/* ===== 分页 ===== */
.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 14px;
  margin-top: 14px;
}

.pager-btn {
  padding: 5px 16px;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 1px;
  cursor: pointer;
  transition: color .18s, border-color .18s;
}

.pager-btn:hover:not(:disabled) { color: var(--gold-soft); border-color: var(--gold); }
.pager-btn:disabled { opacity: .4; cursor: not-allowed; }

.pager-info { font-size: 12px; color: var(--text-soft); letter-spacing: 1px; }

/* ===== 我的任务牌 ===== */
.my-wrap {
  border-top: 1px dashed rgba(196, 154, 92, .25);
  padding-top: 18px;
}

.my-head {
  display: flex;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 12px;
}

.my-head h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 18px;
  letter-spacing: 3px;
  color: var(--gold-soft);
  margin: 0;
}

.my-hint { font-size: 12px; color: var(--text-dim); letter-spacing: 1px; }

.my-refresh {
  margin-left: auto;
  padding: 4px 12px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(12, 8, 18, .5);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  cursor: pointer;
  transition: color .18s, border-color .18s;
}

.my-refresh:hover { color: var(--gold-soft); border-color: var(--gold); }

.status-pill {
  padding: 2px 10px;
  font-size: 11px;
  letter-spacing: 1px;
  border-radius: 999px;
  border: 1px solid var(--border-strong);
  color: var(--text-soft);
}

.status-pill.s-0 {
  color: #e2c46e;
  border-color: rgba(226, 196, 110, .5);
  background: rgba(226, 196, 110, .08);
}

.status-pill.s-1 {
  color: #9fd0a8;
  border-color: rgba(159, 208, 168, .5);
  background: rgba(159, 208, 168, .08);
}

.status-pill.s-2 { color: var(--text-dim); }

.my-actions { display: inline-flex; gap: 6px; }

.mini-btn {
  padding: 5px 12px;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  cursor: pointer;
  transition: color .18s, border-color .18s;
}

.mini-btn:hover:not(:disabled) { color: var(--gold-soft); border-color: var(--gold); }

.mini-btn.primary {
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .85), rgba(200, 16, 46, .65));
  color: #f7e9c4;
}

.mini-btn:disabled { opacity: .6; cursor: wait; }

/* ===== 发布悬赏弹窗 ===== */
.mask {
  position: fixed;
  inset: 0;
  z-index: 60;
  display: grid;
  place-items: center;
  padding: 24px;
  background: rgba(6, 4, 9, .78);
  backdrop-filter: blur(4px);
}

.publish-panel {
  position: relative;
  width: 100%;
  max-width: 640px;
  max-height: 86vh;
  overflow-y: auto;
  padding: 26px 28px;
  border: 1px solid var(--gold);
  border-radius: 18px;
  background:
    radial-gradient(120% 80% at 50% -20%, rgba(200, 16, 46, .28), transparent 60%),
    var(--card-solid, #150d1b);
  box-shadow: 0 0 0 1px rgba(212, 175, 55, .18), 0 30px 80px rgba(0, 0, 0, .7);
}

.publish-close {
  position: absolute;
  top: 12px;
  right: 14px;
  width: 28px;
  height: 28px;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  background: transparent;
  color: var(--text-soft);
  cursor: pointer;
  font-family: inherit;
}

.publish-close:hover { color: var(--gold-soft); border-color: var(--gold); }

.publish-title {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 20px;
  letter-spacing: 3px;
  color: #f3e8d6;
  margin: 0 0 6px;
}

.publish-sub {
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .7);
  margin: 0 0 16px;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px 16px;
}

.field { display: flex; flex-direction: column; gap: 6px; }

.field span {
  font-size: 12px;
  letter-spacing: 2px;
  color: var(--gold-soft);
}

.field input,
.field select,
.field textarea {
  padding: 9px 12px;
  border: 1px solid var(--border);
  border-radius: 9px;
  background: rgba(8, 5, 12, .85);
  color: var(--text);
  font-family: inherit;
  font-size: 14px;
  letter-spacing: 1px;
  outline: none;
  transition: border-color .18s;
  resize: vertical;
}

.field input:focus,
.field select:focus,
.field textarea:focus { border-color: var(--gold); }

.field-wide { grid-column: 1 / -1; }

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 16px;
}

.btn-ghost {
  padding: 8px 18px;
  border: 1px solid var(--border-strong);
  border-radius: 9px;
  background: transparent;
  color: var(--text-soft);
  font-family: inherit;
  letter-spacing: 2px;
  cursor: pointer;
}

.btn-ghost:hover { color: var(--text); border-color: var(--gold); }

.btn-primary {
  padding: 8px 18px;
  border: 1px solid var(--gold);
  border-radius: 9px;
  background: linear-gradient(135deg, rgba(140, 15, 29, .85), rgba(200, 16, 46, .65));
  color: #f7e9c4;
  font-family: inherit;
  letter-spacing: 2px;
  cursor: pointer;
  box-shadow: 0 4px 14px rgba(200, 16, 46, .35);
}

.btn-primary:disabled { opacity: .6; cursor: wait; }

/* ===== 页脚 / 响应式 ===== */
.page-foot {
  padding: 16px 32px 20px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .5);
  border-top: 1px solid var(--border);
}

@media (max-width: 780px) {
  .hero { padding: 26px 18px 18px; flex-wrap: wrap; }
  .hero h1 { font-size: 21px; letter-spacing: 2px; }
  .publish-btn { margin-left: 0; }
  .tabs-wrap { padding: 0 18px 20px; }
  .row { flex-wrap: wrap; }
  .row-meta { display: none; }
  .row-main p { white-space: normal; }
  .form-grid { grid-template-columns: 1fr; }
}
</style>
