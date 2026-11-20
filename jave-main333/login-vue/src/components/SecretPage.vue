<template>
  <div class="page">
    <SectNav active="secret" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 秘境名 + 血功池 -->
    <header class="hero">
      <div class="hero-side" aria-hidden="true">
        <span class="hero-rune">机</span><span class="hero-rune">缘</span><span class="hero-rune">造</span><span class="hero-rune">化</span>
      </div>
      <div class="hero-core">
        <span class="hero-seal">秘</span>
        <div class="hero-text">
          <h1>秘 境</h1>
          <p class="hero-desc">{{ rootDesc }}</p>
        </div>
        <div class="treasury" title="当前可用贡献值">
          <span class="treasury-label">血功池</span>
          <span class="treasury-num">{{ secretAvailable }}</span>
          <span class="treasury-unit">贡献值</span>
        </div>
      </div>
      <div class="hero-side right" aria-hidden="true">
        <span class="hero-rune">生</span><span class="hero-rune">死</span><span class="hero-rune">由</span><span class="hero-rune">天</span>
      </div>
    </header>

    <!-- 探索入口（天机引路需贡献值） -->
    <section class="explore">
      <div class="explore-fee" :class="{ poor: secretAvailable < ROAM_FEE }">
        <span class="fee-label">天机引路费</span>
        <span class="fee-num">{{ ROAM_FEE }}</span>
        <span class="fee-unit">贡献值 / 次</span>
        <small class="fee-balance">血功池 {{ secretAvailable }}</small>
      </div>
      <button class="explore-btn" type="button" :disabled="exploring || secretAvailable < ROAM_FEE" @click="onExplore">
        {{ exploring ? '推 演 天 机 中……' : '耗 贡 献 · 随 机 探 秘' }}
      </button>
      <p v-if="secretAvailable < ROAM_FEE" class="explore-warn">
        贡献值不足，天机不启 —— <span class="goto-quest" @click="emit('nav', 'quest')">去任务阁交差赚贡献值 →</span>
      </p>
      <p v-else class="explore-hint">吉凶自负，生死由天</p>
    </section>

    <!-- 探索奇遇弹层 -->
    <div v-if="found" class="detail-mask" @click.self="found = null">
      <div class="detail-panel explore-panel">
        <button class="detail-close" type="button" @click="found = null">✕</button>
        <p class="explore-label">—— 天 机 引 导 ——</p>
        <div class="explore-head">
          <span class="explore-icon">{{ found.icon || '🗺️' }}</span>
          <div>
            <h2>{{ found.title }}<small v-if="found.grade" class="grade-badge">{{ found.grade }}</small></h2>
            <p class="detail-crumb">{{ found.categoryName }} · 已有 {{ found.viewCount }} 道友探过</p>
          </div>
        </div>
        <p class="explore-fee-done" v-if="found.fee !== undefined">
          {{ found.fee > 0 ? `此行破费 ${found.fee} 贡献值（天机引路费）` : '此秘境你已开辟过，免费重游' }}
        </p>
        <p class="explore-text">{{ found.encounter }}</p>
        <p class="detail-desc">{{ found.description }}</p>
        <div v-if="found.rewards && found.rewards.length" class="reward-list">
          <p class="reward-title">—— 此行收获 ——</p>
          <div
            v-for="(rw, i) in found.rewards"
            :key="i"
            class="reward-item"
            :class="'r-' + rw.rarity"
          >
            <span class="reward-icon">{{ rw.icon }}</span>
            <span class="reward-name">{{ rw.name }}</span>
            <span v-if="rw.amount > 0" class="reward-amount">+{{ rw.amount }}</span>
            <span class="reward-rarity">{{ rarityText(rw.rarity) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 秘境名录 -->
    <section class="tabs-wrap">
      <div class="tabs">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          type="button"
          class="tab"
          :class="{ active: tab.id === activeTab }"
          @click="switchTab(tab.id)"
        >
          <span class="tab-icon">{{ tab.icon }}</span>{{ tab.name }}
          <small v-if="counts[tab.id]" class="tab-count">{{ counts[tab.id] }}</small>
        </button>
      </div>

      <p v-if="error" class="empty">{{ error }}</p>
      <p v-else-if="!loading && !list.length" class="empty">此境尚未收录洞天</p>

      <!-- 破界名录：一条条秘境长卷 -->
      <ul v-else class="scroll-list">
        <li
          v-for="item in list"
          :key="item.id"
          class="scroll-row"
          :class="gradeClass(item.grade)"
          @click="openDetail(item)"
        >
          <div class="spine" aria-hidden="true"></div>
          <span class="row-rune">{{ item.icon || '🗺️' }}</span>
          <div class="row-body">
            <div class="row-title-line">
              <h3 class="row-title">{{ item.title }}</h3>
              <span v-if="item.grade" class="grade-badge">{{ item.grade }}</span>
              <span v-if="isEntered(item.id)" class="entered-badge">已开辟</span>
            </div>
            <p class="row-desc">{{ item.description }}</p>
            <div class="row-tags">
              <span class="tag">{{ item.categoryName }}</span>
              <span class="tag">{{ item.viewCount }} 道友探过</span>
            </div>
          </div>
          <div class="cost-plaque" :class="{ free: !(item.requiredContribution > 0) }">
            <template v-if="isEntered(item.id)">
              <span class="cost-done">✦ 已开辟 · 免费重游</span>
            </template>
            <template v-else-if="item.requiredContribution > 0">
              <span class="cost-num">{{ item.requiredContribution }}</span>
              <span class="cost-unit">门票 · 贡献值</span>
            </template>
            <template v-else>
              <span class="cost-free">无主之境</span>
              <span class="cost-free-sub">随意进出</span>
            </template>
          </div>
          <span class="row-arrow" aria-hidden="true">▸</span>
        </li>
      </ul>

      <div v-if="pages > 1" class="pager">
        <button type="button" class="pager-btn" :disabled="page <= 1" @click="gotoPage(page - 1)">上一页</button>
        <span class="pager-info">第 {{ page }} / {{ pages }} 页 · 共 {{ total }} 境</span>
        <button type="button" class="pager-btn" :disabled="page >= pages" @click="gotoPage(page + 1)">下一页</button>
      </div>
    </section>

    <footer class="page-foot">© 2026 逆天魔宗 · 秘境 · 无尽机缘，待你开辟</footer>

    <!-- 详情弹层 -->
    <div v-if="detail" class="detail-mask" @click.self="closeDetail">
      <div class="detail-panel">
        <button class="detail-close" type="button" @click="closeDetail">✕</button>
        <div class="explore-head">
          <span class="explore-icon">{{ detail.icon || '🗺️' }}</span>
          <div>
            <h2>{{ detail.title }}<small v-if="detail.grade" class="grade-badge">{{ detail.grade }}</small></h2>
            <p class="detail-crumb">{{ detail.categoryPath }}</p>
          </div>
        </div>
        <p v-if="detailLoading" class="empty">探查中……</p>
        <p v-else class="detail-desc">{{ detail.description }}</p>
        <p class="detail-meta">{{ detail.viewCount }} 人阅过</p>

        <!-- ===== 破界区（贡献值经济：玄阶以上收门票，低端为无主之境） ===== -->
        <div v-if="detail" class="enter-box" :class="{ free: !(detail.requiredContribution > 0) }">
          <template v-if="isEntered(detail.id)">
            <span class="entered-tag">✅ 已开辟 · 免费重游</span>
          </template>
          <template v-else-if="detail.requiredContribution > 0">
            <div class="cost-hero">
              <span class="cost-hero-label">破界门票</span>
              <span class="cost-hero-num">{{ detail.requiredContribution }}</span>
              <span class="cost-hero-unit">贡献值</span>
              <span class="cost-hero-balance">血功池 {{ secretAvailable }}</span>
            </div>
            <button type="button" class="enter-btn" :disabled="entering" @click="enter">
              {{ entering ? '破界中……' : '破界进入此秘境' }}
            </button>
            <p v-if="secretAvailable < detail.requiredContribution" class="cost-warn">
              贡献值不足 —— <span class="goto-quest" @click="emit('nav', 'quest')">去任务阁交差赚贡献值 →</span>
            </p>
          </template>
          <template v-else>
            <div class="free-note">
              <span class="free-tag">无主之境 · 随意进出</span>
              <small>无人看守，收获寒酸，胜在分文不取</small>
            </div>
            <button type="button" class="enter-btn" :disabled="entering" @click="enter">
              {{ entering ? '进入中……' : '随意进入此境' }}
            </button>
          </template>
          <div v-if="enterRewards.length" class="reward-list">
            <p class="reward-title">—— 此行收获 ——</p>
            <div
              v-for="(rw, i) in enterRewards"
              :key="i"
              class="reward-item"
              :class="'r-' + rw.rarity"
            >
              <span class="reward-icon">{{ rw.icon }}</span>
              <span class="reward-name">{{ rw.name }}</span>
              <span v-if="rw.amount > 0" class="reward-amount">+{{ rw.amount }}</span>
              <span class="reward-rarity">{{ rarityText(rw.rarity) }}</span>
            </div>
          </div>
        </div>
        <div v-if="related.length" class="detail-related">
          <h3>相邻秘境</h3>
          <div class="related-chips">
            <button
              v-for="r in related"
              :key="r.id"
              type="button"
              class="related-chip"
              @click="openDetail(r)"
            >{{ r.icon || '🗺️' }} {{ r.title }}</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import { fetchHomeSummary, fetchItemDetail, fetchRelatedItems, searchItems } from '../api/home'
import { fetchSecretStatus, enterSecret, roamSecret } from '../api/secret'

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

/** 随机探秘的「天机引路费」，与后端 SecretService.ROAM_FEE 对齐 */
const ROAM_FEE = 20

const rootDesc = ref('无尽秘境，待你开辟')
const tabs = ref([{ id: 0, name: '全部秘境', icon: '🗺️' }])
const activeTab = ref(0)
const counts = ref({})

const loading = ref(false)
const error = ref('')
const list = ref([])
const page = ref(1)
const pageSize = 10
const pages = ref(0)
const total = ref(0)

// 探索
const exploring = ref(false)
const found = ref(null)

// 详情弹层
const detail = ref(null)
const related = ref([])
const detailLoading = ref(false)

// 贡献值经济（秘境破界）：可用余额 + 已开辟秘境 id
const secretAvailable = ref(0)
const enteredIds = ref([])
const entering = ref(false)
// 最近一次破界 / 探索的奖励（展示用）
const enterRewards = ref([])

function rarityText(rarity) {
  return { common: '普通', rare: '稀有', epic: '史诗', legendary: '传说' }[rarity] || '普通'
}

let secretRootId = 0

/** 品阶 → 血书脊色（天/圣/神品猩红，地/王品紫煞，玄品幽蓝，黄/凡品暗金） */
function gradeClass(grade) {
  const g = String(grade || '')
  if (/[天圣神魔]/.test(g)) return 'g-heaven'
  if (/[地王皇]/.test(g)) return 'g-earth'
  if (/玄/.test(g)) return 'g-mystic'
  if (/[黄凡]/.test(g)) return 'g-common'
  return ''
}

onMounted(async () => {
  try {
    const data = await fetchHomeSummary()
    counts.value = data.categoryCounts || {}
    const root = (data.categories || []).find(c => c.name === '秘境')
    if (root) {
      secretRootId = root.id
      if (root.description) rootDesc.value = root.description
      tabs.value = [
        { id: root.id, name: '全部秘境', icon: root.icon || '🗺️' },
        ...(root.children || []).map(c => ({ id: c.id, name: c.name, icon: c.icon || '🌫️' }))
      ]
      activeTab.value = root.id
    }
  } catch (e) {
    showToast(e.message || '秘境数据加载失败')
  }
  loadSecretStatus()
  await load()
})

async function load(toPage = 1) {
  loading.value = true
  error.value = ''
  try {
    const data = await searchItems({
      keyword: '',
      categoryId: activeTab.value || secretRootId || undefined,
      sort: 'hot',
      page: toPage,
      size: pageSize
    })
    list.value = data.list || []
    total.value = data.total || 0
    pages.value = data.pages || 0
    page.value = data.page || toPage
  } catch (e) {
    error.value = e.message || '秘境检索失败'
  } finally {
    loading.value = false
  }
}

function switchTab(id) {
  if (activeTab.value === id) return
  activeTab.value = id
  load(1)
}

function gotoPage(p) {
  if (p < 1 || p > pages.value || p === page.value) return
  load(p)
}

/** 贡献值余额与已开辟秘境（失败静默：不影响浏览秘境名录） */
async function loadSecretStatus() {
  try {
    const s = await fetchSecretStatus(props.username)
    secretAvailable.value = s.contributionAvailable ?? 0
    enteredIds.value = s.enteredIds || []
  } catch { /* 未登录或后端未就绪时忽略 */ }
}

function isEntered(id) {
  return enteredIds.value.includes(id)
}

/** 随机探秘：收「天机引路费」，随机挑秘境并生成奇遇文案 */
async function onExplore() {
  if (exploring.value) return
  exploring.value = true
  try {
    found.value = await roamSecret(props.username)
    await loadSecretStatus()
  } catch (e) {
    showToast(e.message || '探索失败，天机紊乱')
  } finally {
    exploring.value = false
  }
}

async function openDetail(entry) {
  detailLoading.value = true
  detail.value = { ...entry }
  related.value = []
  enterRewards.value = []
  try {
    const [d, rel] = await Promise.all([
      fetchItemDetail(entry.id),
      fetchRelatedItems(entry.id, 4).catch(() => [])
    ])
    detail.value = d
    related.value = rel || []
  } catch (e) {
    showToast(e.message || '详情加载失败')
  } finally {
    detailLoading.value = false
  }
}

function closeDetail() {
  detail.value = null
  related.value = []
}

/** 破界进入秘境：扣门票贡献值，首入掷探索奖励 */
async function enter() {
  if (!detail.value || entering.value) return
  entering.value = true
  try {
    const res = await enterSecret(props.username, detail.value.id)
    const rewards = (res && res.rewards) || []
    if (!enteredIds.value.includes(detail.value.id)) {
      enteredIds.value.push(detail.value.id)
    }
    enterRewards.value = rewards
    const highlights = rewards
      .filter(rw => rw.rarity === 'epic' || rw.rarity === 'legendary')
      .map(rw => rw.name)
    showToast(highlights.length
      ? `破界成功！「${detail.value.title}」已开辟，竟得 ${highlights.join('、')}！`
      : `破界成功！「${detail.value.title}」已开辟，可随时重游`)
    await loadSecretStatus()
  } catch (e) {
    showToast(e.message || '破界失败')
  } finally {
    entering.value = false
  }
}
</script>

<style scoped>
.page {
  position: relative;
  width: 100%;
  max-width: 1320px;
  margin: 0 auto;
  background: rgba(8, 5, 12, .22);
  border: 1px solid rgba(196, 154, 92, .18);
  border-radius: 22px;
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .06),
    0 24px 60px rgba(0, 0, 0, .50),
    0 0 50px rgba(200, 16, 46, .12);
}

/* ===== 秘境名 + 血功池 ===== */
.hero {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 30px 26px 20px;
  border-bottom: 1px solid rgba(196, 154, 92, .16);
  background:
    radial-gradient(60% 120% at 50% -30%, rgba(200, 16, 46, .22), transparent 70%),
    rgba(10, 6, 14, .5);
}

.hero-core {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  min-width: 0;
}

.hero-seal {
  width: 54px;
  height: 54px;
  border-radius: 10px;
  display: grid;
  place-items: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 32px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #6b0a16, #c8102e 70%, #8c0f1d);
  border: 2px solid var(--gold);
  box-shadow: 0 0 22px rgba(200, 16, 46, .55), inset 0 0 12px rgba(0, 0, 0, .45);
  transform: rotate(-6deg);
  flex-shrink: 0;
  animation: seal-pulse 3.6s ease-in-out infinite;
}

@keyframes seal-pulse {
  0%, 100% { box-shadow: 0 0 18px rgba(200, 16, 46, .45), inset 0 0 12px rgba(0, 0, 0, .45); }
  50% { box-shadow: 0 0 34px rgba(200, 16, 46, .75), inset 0 0 12px rgba(0, 0, 0, .45); }
}

.hero h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 28px;
  font-weight: 700;
  letter-spacing: 6px;
  color: #f3e8d6;
  text-shadow: 0 0 22px rgba(200, 16, 46, .6), 0 2px 4px rgba(0, 0, 0, .6);
  margin: 0;
  white-space: nowrap;
}

.hero-desc {
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(212, 175, 55, .75);
  margin: 6px 0 0;
}

/* 血功池：贡献值余额，大字高亮 */
.treasury {
  display: flex;
  align-items: baseline;
  gap: 8px;
  padding: 10px 18px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 12px;
  background:
    linear-gradient(135deg, rgba(140, 15, 29, .55), rgba(60, 8, 16, .8)),
    rgba(12, 8, 18, .8);
  box-shadow: 0 0 18px rgba(200, 16, 46, .35), inset 0 0 14px rgba(0, 0, 0, .4);
  flex-shrink: 0;
}

.treasury-label {
  font-size: 12px;
  letter-spacing: 2px;
  color: rgba(247, 233, 196, .85);
}

.treasury-num {
  font-size: 26px;
  font-weight: 700;
  line-height: 1;
  color: #ffe9a8;
  text-shadow: 0 0 14px rgba(212, 175, 55, .75);
  font-variant-numeric: tabular-nums;
}

.treasury-unit {
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .85);
}

/* 两侧符文柱 */
.hero-side {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.hero-rune {
  width: 26px;
  height: 26px;
  display: grid;
  place-items: center;
  font-size: 12px;
  color: rgba(200, 16, 46, .75);
  border: 1px solid rgba(200, 16, 46, .3);
  border-radius: 4px;
  background: rgba(30, 6, 12, .45);
}

/* ===== 探索入口 ===== */
.explore {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 18px 32px 26px;
  border-bottom: 1px solid rgba(196, 154, 92, .14);
  background: rgba(10, 6, 14, .35);
}

/* 天机引路费价牌 */
.explore-fee {
  display: flex;
  align-items: baseline;
  gap: 8px;
  padding: 10px 22px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 12px;
  background:
    linear-gradient(135deg, rgba(140, 15, 29, .45), rgba(45, 8, 14, .8)),
    rgba(12, 8, 18, .8);
  box-shadow: 0 0 16px rgba(200, 16, 46, .3), inset 0 0 12px rgba(0, 0, 0, .35);
}

.fee-label {
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(247, 233, 196, .85);
}

.fee-num {
  font-size: 28px;
  font-weight: 700;
  line-height: 1;
  color: #ffe9a8;
  text-shadow: 0 0 16px rgba(212, 175, 55, .8);
  font-variant-numeric: tabular-nums;
}

.fee-unit {
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .85);
}

.fee-balance {
  margin-left: 10px;
  padding: 2px 10px;
  font-size: 12px;
  border-radius: 999px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .85);
  border: 1px solid rgba(196, 154, 92, .35);
  background: rgba(12, 8, 18, .55);
}

.explore-fee.poor { border-color: rgba(232, 122, 122, .55); }
.explore-fee.poor .fee-num { color: #ff9aa6; }

.explore-hint {
  font-size: 12px;
  letter-spacing: 4px;
  color: rgba(226, 58, 78, .75);
}

.explore-warn {
  margin: 0;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(232, 122, 122, .9);
}

.explore-btn {
  padding: 14px 64px;
  border: 1px solid rgba(212, 175, 55, .6);
  border-radius: 999px;
  cursor: pointer;
  background: linear-gradient(135deg, #8c0f1d 0%, #c8102e 55%, #e23a4e 100%);
  color: #f7e9c4;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 19px;
  font-weight: 700;
  letter-spacing: 6px;
  box-shadow:
    0 6px 26px rgba(200, 16, 46, .5),
    inset 0 0 14px rgba(0, 0, 0, .3),
    0 0 40px rgba(212, 175, 55, .12);
  transition: transform .15s, filter .2s;
}

.explore-btn:hover:not(:disabled) { transform: translateY(-2px); filter: brightness(1.12); }
.explore-btn:active:not(:disabled) { transform: translateY(0); }
.explore-btn:disabled { opacity: .55; cursor: not-allowed; transform: none; }

.goto-quest {
  color: var(--gold-soft, #e2c46e);
  cursor: pointer;
}

.goto-quest:hover { text-decoration: underline; }

/* ===== 分堂 tab ===== */
.tabs-wrap { padding: 0 26px 26px; }

.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 16px 0 14px;
}

.tab {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border: 1px solid var(--border);
  border-radius: 6px 14px 6px 14px;
  background: rgba(12, 8, 18, .72);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 14px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s, box-shadow .18s;
}

.tab:hover { color: var(--gold-soft); border-color: var(--gold); }

.tab.active {
  color: #f7e9c4;
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .75), rgba(200, 16, 46, .5));
  box-shadow: 0 0 14px rgba(200, 16, 46, .35);
}

.tab-icon { font-size: 15px; }
.tab-count { font-size: 11px; color: var(--text-dim); letter-spacing: 0; }

/* ===== 破界名录：一条条秘境长卷 ===== */
.empty {
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
  padding: 26px 0;
}

.scroll-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.scroll-row {
  position: relative;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 18px 14px 22px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background:
    linear-gradient(90deg, rgba(24, 10, 20, .85), rgba(12, 8, 18, .92) 40%, rgba(12, 8, 18, .92)),
    rgba(10, 7, 15, .9);
  cursor: pointer;
  overflow: hidden;
  transition: border-color .18s, box-shadow .18s, transform .18s;
}

/* 左侧血书脊：按品阶变色 */
.spine {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: linear-gradient(180deg, rgba(212, 175, 55, .55), rgba(196, 154, 92, .25));
}

.scroll-row.g-heaven .spine { background: linear-gradient(180deg, #ff2e4c, #8c0f1d); }
.scroll-row.g-earth .spine { background: linear-gradient(180deg, #b06cff, #4a1a7a); }
.scroll-row.g-mystic .spine { background: linear-gradient(180deg, #4aa8ff, #173a7a); }
.scroll-row.g-common .spine { background: linear-gradient(180deg, #d4af37, #6b5a20); }

/* 悬停：血气泛起 */
.scroll-row:hover {
  border-color: rgba(200, 16, 46, .55);
  box-shadow: 0 0 20px rgba(200, 16, 46, .25), 0 8px 24px rgba(0, 0, 0, .4);
  transform: translateX(4px);
}

.scroll-row:hover .row-title { color: #ffe9c9; }

.row-rune {
  width: 46px;
  height: 46px;
  display: grid;
  place-items: center;
  font-size: 22px;
  flex-shrink: 0;
  border: 1px solid rgba(212, 175, 55, .35);
  border-radius: 10px;
  background: rgba(30, 12, 20, .6);
  box-shadow: inset 0 0 10px rgba(0, 0, 0, .5);
}

.row-body { flex: 1; min-width: 0; }

.row-title-line {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 4px;
}

.row-title {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 16px;
  letter-spacing: 1px;
  color: #f3e8d6;
  margin: 0;
  transition: color .18s;
}

.grade-badge {
  display: inline-block;
  padding: 1px 9px;
  font-size: 11px;
  border-radius: 999px;
  color: #f7e9c4;
  background: linear-gradient(135deg, rgba(140, 15, 29, .85), rgba(200, 16, 46, .6));
  border: 1px solid rgba(212, 175, 55, .45);
  vertical-align: middle;
  letter-spacing: 1px;
}

.entered-badge {
  display: inline-block;
  padding: 1px 9px;
  font-size: 11px;
  border-radius: 999px;
  color: rgba(120, 220, 160, .95);
  border: 1px solid rgba(120, 220, 160, .4);
  background: rgba(20, 40, 30, .35);
  letter-spacing: 1px;
}

.row-desc {
  font-size: 13px;
  line-height: 1.6;
  color: var(--text-soft);
  margin: 0 0 6px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.row-tags { display: flex; gap: 6px; }

.tag {
  padding: 1px 8px;
  font-size: 11px;
  letter-spacing: 1px;
  border-radius: 4px;
  color: rgba(212, 175, 55, .7);
  border: 1px solid rgba(196, 154, 92, .25);
  background: rgba(12, 8, 18, .5);
}

/* ===== 门票价牌：整行最醒目的元素 ===== */
.cost-plaque {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1px;
  min-width: 96px;
  padding: 8px 14px;
  flex-shrink: 0;
  border: 1px solid rgba(212, 175, 55, .55);
  border-radius: 10px;
  background: linear-gradient(160deg, rgba(140, 15, 29, .5), rgba(45, 8, 14, .85));
  box-shadow: 0 0 14px rgba(200, 16, 46, .3), inset 0 0 12px rgba(0, 0, 0, .35);
}

.cost-num {
  font-size: 24px;
  font-weight: 700;
  line-height: 1.1;
  color: #ffe9a8;
  text-shadow: 0 0 16px rgba(212, 175, 55, .8);
  font-variant-numeric: tabular-nums;
}

.cost-unit {
  font-size: 11px;
  letter-spacing: 2px;
  color: rgba(247, 233, 196, .8);
}

.cost-plaque.free {
  border-color: rgba(120, 220, 160, .4);
  background: linear-gradient(160deg, rgba(20, 45, 32, .6), rgba(12, 20, 16, .85));
  box-shadow: none;
}

.cost-free {
  font-size: 14px;
  letter-spacing: 2px;
  color: rgba(120, 220, 160, .95);
}

.cost-free-sub {
  font-size: 10px;
  letter-spacing: 1px;
  color: rgba(120, 220, 160, .6);
}

.cost-done {
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(120, 220, 160, .95);
  text-align: center;
}

.row-arrow {
  font-size: 16px;
  color: rgba(212, 175, 55, .5);
  flex-shrink: 0;
  transition: color .18s, transform .18s;
}

.scroll-row:hover .row-arrow {
  color: var(--gold-soft);
  transform: translateX(3px);
}

/* ===== 分页 ===== */
.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 14px;
  margin-top: 16px;
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

/* ===== 弹层 ===== */
.detail-mask {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: grid;
  place-items: center;
  padding: 24px;
  background: rgba(6, 4, 9, .78);
  backdrop-filter: blur(4px);
}

.detail-panel {
  position: relative;
  width: 100%;
  max-width: 560px;
  max-height: 80vh;
  overflow-y: auto;
  padding: 26px 28px;
  border: 1px solid var(--gold);
  border-radius: 18px;
  background:
    radial-gradient(120% 80% at 50% -20%, rgba(200, 16, 46, .28), transparent 60%),
    var(--card-solid, #150d1b);
  box-shadow: 0 0 0 1px rgba(212, 175, 55, .18), 0 30px 80px rgba(0, 0, 0, .7);
}

.explore-panel {
  border-color: rgba(226, 58, 78, .8);
  box-shadow:
    0 0 0 1px rgba(200, 16, 46, .3),
    0 0 60px rgba(200, 16, 46, .35),
    0 30px 80px rgba(0, 0, 0, .7);
}

.detail-close {
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

.detail-close:hover { color: var(--gold-soft); border-color: var(--gold); }

.explore-label {
  text-align: center;
  font-size: 11px;
  letter-spacing: 6px;
  color: rgba(212, 175, 55, .55);
  margin: 0 0 16px;
}

.explore-fee-done {
  margin: 14px 0 0;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .8);
}

.explore-head {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  padding-right: 34px;
}

.explore-icon { font-size: 36px; line-height: 1.1; flex-shrink: 0; }

.explore-head h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 22px;
  letter-spacing: 2px;
  color: #f3e8d6;
  margin: 0 0 6px;
}

.detail-crumb {
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .7);
  margin: 0;
}

.explore-text {
  margin: 18px 0 14px;
  padding: 14px 16px;
  font-size: 14px;
  line-height: 2;
  color: #f3e8d6;
  background: rgba(200, 16, 46, .12);
  border: 1px solid rgba(200, 16, 46, .35);
  border-radius: 12px;
}

.detail-desc {
  margin: 0 0 12px;
  font-size: 14px;
  line-height: 1.9;
  color: var(--text);
}

.detail-meta {
  font-size: 12px;
  letter-spacing: 1px;
  color: var(--text-dim);
  margin: 0;
}

/* ===== 破界区：门票大价牌 ===== */
.enter-box {
  margin-top: 16px;
  padding: 16px;
  border: 1px solid rgba(212, 175, 55, .4);
  border-radius: 12px;
  background:
    radial-gradient(90% 120% at 50% 0%, rgba(200, 16, 46, .16), transparent 70%),
    rgba(12, 8, 18, .7);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.cost-hero {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.cost-hero-label {
  font-size: 13px;
  letter-spacing: 2px;
  color: var(--text-soft);
}

.cost-hero-num {
  font-size: 40px;
  font-weight: 700;
  line-height: 1;
  color: #ffe9a8;
  text-shadow: 0 0 20px rgba(212, 175, 55, .8), 0 0 40px rgba(200, 16, 46, .4);
  font-variant-numeric: tabular-nums;
}

.cost-hero-unit {
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(247, 233, 196, .85);
}

.cost-hero-balance {
  margin-left: 10px;
  padding: 2px 10px;
  font-size: 12px;
  border-radius: 999px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .85);
  border: 1px solid rgba(196, 154, 92, .35);
  background: rgba(12, 8, 18, .55);
}

.enter-btn {
  padding: 9px 26px;
  border: 1px solid var(--gold);
  border-radius: 10px;
  color: #f7e9c4;
  background: linear-gradient(135deg, rgba(140, 15, 29, .9), rgba(200, 16, 46, .7));
  font-family: inherit;
  font-size: 14px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: box-shadow .18s, transform .18s;
}

.enter-btn:hover:not(:disabled) {
  box-shadow: 0 0 20px rgba(200, 16, 46, .55);
  transform: translateY(-1px);
}

.enter-btn:disabled { opacity: .5; cursor: not-allowed; }

.entered-tag {
  padding: 6px 14px;
  border-radius: 999px;
  font-size: 13px;
  letter-spacing: 1px;
  color: rgba(120, 220, 160, .95);
  border: 1px solid rgba(120, 220, 160, .4);
  background: rgba(20, 40, 30, .4);
}

.cost-warn {
  margin: 0;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(232, 122, 122, .9);
}

/* 无主之境（低端免费秘境）入口 */
.enter-box.free { border-color: rgba(120, 220, 160, .35); }

.free-note {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.free-tag {
  padding: 3px 14px;
  border-radius: 999px;
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(120, 220, 160, .95);
  border: 1px solid rgba(120, 220, 160, .4);
  background: rgba(20, 40, 30, .35);
}

.free-note small {
  font-size: 11px;
  letter-spacing: 1px;
  color: var(--text-dim);
}

/* ===== 探索收获（奖励列表） ===== */
.reward-list {
  width: 100%;
  margin-top: 4px;
  padding-top: 12px;
  border-top: 1px dashed rgba(196, 154, 92, .3);
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.reward-title {
  margin: 0 0 2px;
  text-align: center;
  font-size: 11px;
  letter-spacing: 4px;
  color: rgba(212, 175, 55, .6);
}

.reward-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 12px;
  border-radius: 8px;
  border: 1px solid rgba(196, 154, 92, .25);
  background: rgba(12, 8, 18, .6);
  font-size: 13px;
}

.reward-icon { font-size: 16px; flex-shrink: 0; }

.reward-name {
  flex: 1;
  min-width: 0;
  color: #f3e8d6;
  letter-spacing: 1px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.reward-amount {
  font-weight: 700;
  color: #ffe9a8;
  font-variant-numeric: tabular-nums;
}

.reward-rarity {
  flex-shrink: 0;
  padding: 1px 8px;
  font-size: 10px;
  border-radius: 999px;
  letter-spacing: 1px;
}

/* 稀有度配色 */
.r-common { border-color: rgba(196, 154, 92, .25); }
.r-common .reward-rarity { color: rgba(154, 143, 176, .9); border: 1px solid rgba(154, 143, 176, .35); }

.r-rare { border-color: rgba(74, 168, 255, .45); }
.r-rare .reward-rarity { color: #7db8ff; border: 1px solid rgba(74, 168, 255, .5); }

.r-epic { border-color: rgba(176, 108, 255, .5); background: rgba(50, 20, 70, .35); }
.r-epic .reward-rarity { color: #cf9aff; border: 1px solid rgba(176, 108, 255, .55); }

.r-legendary {
  border-color: rgba(255, 176, 55, .6);
  background: linear-gradient(135deg, rgba(120, 60, 8, .4), rgba(60, 30, 6, .5));
  box-shadow: 0 0 12px rgba(255, 176, 55, .25);
}
.r-legendary .reward-rarity { color: #ffc46e; border: 1px solid rgba(255, 176, 55, .6); }

.detail-related {
  margin-top: 22px;
  padding-top: 16px;
  border-top: 1px solid var(--border);
}

.detail-related h3 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 15px;
  letter-spacing: 2px;
  color: var(--gold-soft);
  margin: 0 0 10px;
}

.related-chips { display: flex; flex-wrap: wrap; gap: 8px; }

.related-chip {
  padding: 5px 12px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(12, 8, 18, .72);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  cursor: pointer;
  transition: color .18s, border-color .18s;
}

.related-chip:hover { color: var(--gold-soft); border-color: var(--gold); }

/* ===== 页脚 / 响应式 ===== */
.page-foot {
  padding: 16px 26px 20px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .5);
  border-top: 1px solid var(--border);
}

@media (max-width: 780px) {
  .hero { padding: 24px 16px 16px; flex-wrap: wrap; }
  .hero-side { display: none; }
  .hero h1 { font-size: 22px; letter-spacing: 3px; }
  .hero-core { width: 100%; justify-content: flex-start; }
  .tabs-wrap { padding: 0 16px 20px; }
  .explore { padding: 16px 16px 20px; }
  .explore-btn { width: 100%; padding: 13px 0; }
  .explore-fee { flex-wrap: wrap; justify-content: center; }
  .cost-plaque { min-width: 76px; padding: 6px 10px; }
  .cost-num { font-size: 19px; }
  .row-desc { white-space: normal; }
  .row-arrow { display: none; }
}
</style>
