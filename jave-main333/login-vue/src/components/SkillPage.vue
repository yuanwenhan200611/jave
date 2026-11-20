<template>
  <div class="page">
    <SectNav active="skill" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 阁名 + 血功池 -->
    <header class="hero">
      <div class="hero-side" aria-hidden="true">
        <span class="hero-rune">血</span><span class="hero-rune">煞</span><span class="hero-rune">噬</span><span class="hero-rune">天</span>
      </div>
      <div class="hero-core">
        <span class="hero-seal">魔</span>
        <div class="hero-text">
          <h1>功 法 阁</h1>
          <p class="hero-desc">{{ rootDesc }}</p>
        </div>
        <div class="treasury" title="当前可用贡献值">
          <span class="treasury-label">血功池</span>
          <span class="treasury-num">{{ skillAvailable }}</span>
          <span class="treasury-unit">贡献值</span>
        </div>
      </div>
      <div class="hero-side right" aria-hidden="true">
        <span class="hero-rune">万</span><span class="hero-rune">法</span><span class="hero-rune">归</span><span class="hero-rune">宗</span>
      </div>
    </header>

    <!-- 分堂腰牌 + 排序 -->
    <section class="tabs-wrap">
      <div class="toolbar">
        <div class="tabs">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            type="button"
            class="tab"
            :class="{ active: tab.id === activeTab }"
            @click="switchTab(tab.id)"
          >
            <span class="tab-icon">{{ tab.icon }}</span>
            <span class="tab-name">{{ tab.name }}</span>
            <small v-if="counts[tab.id]" class="tab-count">{{ counts[tab.id] }}</small>
          </button>
        </div>

        <div class="sort-bar">
          <span class="sort-label">排序</span>
          <button
            v-for="s in sortOptions"
            :key="s.value"
            type="button"
            class="sort-btn"
            :class="{ active: sort === s.value }"
            @click="changeSort(s.value)"
          >{{ s.label }}</button>
        </div>
      </div>

      <p v-if="error" class="empty">{{ error }}</p>
      <p v-else-if="!loading && !list.length" class="empty">此阁暂未收录功法，另择高就</p>

      <!-- 玉简血书：一条条功法长卷 -->
      <ul v-else class="scroll-list">
        <li
          v-for="item in list"
          :key="item.id"
          class="scroll-row"
          :class="gradeClass(item.grade)"
          @click="openDetail(item)"
        >
          <div class="spine" aria-hidden="true"></div>
          <span class="row-rune">{{ item.icon || '📜' }}</span>
          <div class="row-body">
            <div class="row-title-line">
              <h3 class="row-title">{{ item.title }}</h3>
              <span v-if="item.grade" class="grade-badge">{{ item.grade }}</span>
              <span v-if="isLearned(item.id)" class="learned-badge">已参悟</span>
            </div>
            <p class="row-desc">{{ item.description }}</p>
            <div class="row-tags">
              <span class="tag">{{ item.categoryName }}</span>
              <span class="tag">{{ item.viewCount }} 人参悟</span>
            </div>
          </div>
          <div class="cost-plaque" :class="{ free: !(item.requiredContribution > 0) }">
            <template v-if="isLearned(item.id)">
              <span class="cost-done">✦ 已收录洞府</span>
            </template>
            <template v-else-if="item.requiredContribution > 0">
              <span class="cost-num">{{ item.requiredContribution }}</span>
              <span class="cost-unit">贡献值</span>
            </template>
            <template v-else>
              <span class="cost-free">免贡参悟</span>
            </template>
          </div>
          <span class="row-arrow" aria-hidden="true">▸</span>
        </li>
      </ul>

      <div v-if="pages > 1" class="pager">
        <button type="button" class="pager-btn" :disabled="page <= 1" @click="gotoPage(page - 1)">上一页</button>
        <span class="pager-info">第 {{ page }} / {{ pages }} 页 · 共 {{ total }} 卷</span>
        <button type="button" class="pager-btn" :disabled="page >= pages" @click="gotoPage(page + 1)">下一页</button>
      </div>
    </section>

    <footer class="page-foot">© 2026 逆天魔宗 · 功法阁 · 万法归宗</footer>

    <!-- 详情弹层 -->
    <div v-if="detail" class="detail-mask" @click.self="closeDetail">
      <div class="detail-panel">
        <button class="detail-close" type="button" @click="closeDetail">✕</button>
        <div class="detail-head">
          <span class="detail-icon">{{ detail.icon || '📜' }}</span>
          <div>
            <h2>{{ detail.title }}<small v-if="detail.grade" class="grade-badge">{{ detail.grade }}</small></h2>
            <p class="detail-crumb">{{ detail.categoryPath }}</p>
          </div>
        </div>
        <p v-if="detailLoading" class="empty">翻阅中……</p>
        <p v-else class="detail-desc">{{ detail.description }}</p>
        <p class="detail-meta">{{ detail.viewCount }} 人参悟</p>

        <!-- ===== 参悟区（贡献值经济：功法须花贡献值方可习得） ===== -->
        <div v-if="detail && detail.requiredContribution > 0" class="learn-box">
          <template v-if="isLearned(detail.id)">
            <span class="learned-tag">✅ 已参悟 · 收录洞府</span>
          </template>
          <template v-else>
            <div class="cost-hero">
              <span class="cost-hero-label">参悟所需</span>
              <span class="cost-hero-num">{{ detail.requiredContribution }}</span>
              <span class="cost-hero-unit">贡献值</span>
              <span class="cost-hero-balance">血功池 {{ skillAvailable }}</span>
            </div>
            <button type="button" class="learn-btn" :disabled="learning" @click="learn">
              {{ learning ? '参悟中……' : '血契参悟此功' }}
            </button>
            <p v-if="skillAvailable < detail.requiredContribution" class="cost-warn">
              贡献值不足 —— <span class="goto-quest" @click="emit('nav', 'quest')">去任务阁交差赚贡献值 →</span>
            </p>
          </template>
        </div>
        <div v-if="related.length" class="detail-related">
          <h3>同源功法</h3>
          <div class="related-chips">
            <button
              v-for="r in related"
              :key="r.id"
              type="button"
              class="related-chip"
              @click="openDetail(r)"
            >{{ r.icon || '📜' }} {{ r.title }}</button>
          </div>
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
  fetchHomeSummary,
  fetchItemDetail,
  fetchRelatedItems,
  searchItems
} from '../api/home'
import { fetchSkillStatus, learnSkill } from '../api/skill'

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const rootDesc = ref('诸天功法，皆可习练')
const tabs = ref([{ id: 0, name: '全部功法', icon: '📜' }])
const activeTab = ref(0)
const counts = ref({})
const sort = ref('hot')
const sortOptions = [
  { value: 'hot', label: '最热' },
  { value: 'new', label: '最新' },
  { value: 'grade', label: '品阶' },
  { value: 'title', label: '名称' }
]

const loading = ref(false)
const error = ref('')
const list = ref([])
const page = ref(1)
const pageSize = 10
const total = ref(0)
const pages = ref(0)

// 详情弹层
const detail = ref(null)
const related = ref([])
const detailLoading = ref(false)

// 贡献值经济（功法参悟）：可用余额 + 已参悟功法 id
const skillAvailable = ref(0)
const learnedIds = ref([])
const learning = ref(false)

/** 功法顶级分类 id（含子孙计数） */
let skillRootId = 0

/** 品阶 → 血书脊色（天/圣/神品猩红，地/王品紫煞，玄品幽蓝，黄/凡品暗金） */
function gradeClass(grade) {
  const g = String(grade || '')
  if (/[天圣神魔]/.test(g)) return 'g-heaven'
  if (/[地王皇]/.test(g)) return 'g-earth'
  if (/玄/.test(g)) return 'g-mystic'
  if (/[黄凡凡]/.test(g)) return 'g-common'
  return ''
}

onMounted(async () => {
  try {
    const data = await fetchHomeSummary()
    counts.value = data.categoryCounts || {}
    const root = (data.categories || []).find(c => c.name === '功法')
    if (root) {
      skillRootId = root.id
      if (root.description) rootDesc.value = root.description
      tabs.value = [
        { id: root.id, name: '全部功法', icon: root.icon || '📜' },
        ...(root.children || []).map(c => ({ id: c.id, name: c.name, icon: c.icon || '📜' }))
      ]
      activeTab.value = root.id
    }
  } catch (e) {
    showToast(e.message || '功法阁数据加载失败')
  }
  loadSkillStatus()
  await load()
})

async function load(toPage = 1) {
  loading.value = true
  error.value = ''
  try {
    const data = await searchItems({
      keyword: '',
      categoryId: activeTab.value || skillRootId || undefined,
      sort: sort.value,
      page: toPage,
      size: pageSize
    })
    list.value = data.list || []
    total.value = data.total || 0
    pages.value = data.pages || 0
    page.value = data.page || toPage
  } catch (e) {
    error.value = e.message || '功法检索失败'
  } finally {
    loading.value = false
  }
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

async function openDetail(entry) {
  detailLoading.value = true
  detail.value = { ...entry }
  related.value = []
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

/** 贡献值余额与已参悟列表（失败静默：不影响浏览功法目录） */
async function loadSkillStatus() {
  try {
    const s = await fetchSkillStatus(props.username)
    skillAvailable.value = s.contributionAvailable ?? 0
    learnedIds.value = s.learnedIds || []
  } catch { /* 未登录或后端未就绪时忽略 */ }
}

function isLearned(id) {
  return learnedIds.value.includes(id)
}

/** 参悟功法：扣贡献值，成功后刷新余额并收录洞府 */
async function learn() {
  if (!detail.value || learning.value) return
  learning.value = true
  try {
    await learnSkill(props.username, detail.value.id)
    if (!learnedIds.value.includes(detail.value.id)) {
      learnedIds.value.push(detail.value.id)
    }
    showToast(`参悟成功！「${detail.value.title}」已收录洞府`)
    await loadSkillStatus()
  } catch (e) {
    showToast(e.message || '参悟失败')
  } finally {
    learning.value = false
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

/* ===== 阁名 + 血功池 ===== */
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

/* ===== 分堂腰牌 + 排序 ===== */
.tabs-wrap { padding: 0 26px 26px; }

.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
  margin: 16px 0 14px;
}

.tabs { display: flex; flex-wrap: wrap; gap: 8px; }

.tab {
  display: inline-flex;
  align-items: center;
  gap: 7px;
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

.sort-bar { display: flex; align-items: center; gap: 6px; }

.sort-label {
  font-size: 12px;
  letter-spacing: 2px;
  color: var(--text-dim);
  margin-right: 2px;
}

.sort-btn {
  padding: 4px 13px;
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
  background: linear-gradient(135deg, rgba(140, 15, 29, .75), rgba(200, 16, 46, .5));
}

/* ===== 玉简血书列表：一条条功法长卷 ===== */
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

.learned-badge {
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

/* ===== 贡献值价牌：整行最醒目的元素 ===== */
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

/* ===== 详情弹层 ===== */
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

.detail-head {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  padding-right: 34px;
}

.detail-icon { font-size: 34px; line-height: 1.1; flex-shrink: 0; }

.detail-head h2 {
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

.detail-desc {
  margin: 18px 0 12px;
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

/* ===== 参悟区：贡献值大价牌 ===== */
.learn-box {
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

.learn-btn {
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

.learn-btn:hover:not(:disabled) {
  box-shadow: 0 0 20px rgba(200, 16, 46, .55);
  transform: translateY(-1px);
}

.learn-btn:disabled { opacity: .5; cursor: not-allowed; }

.learned-tag {
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

.goto-quest {
  color: var(--gold-soft, #e2c46e);
  cursor: pointer;
}

.goto-quest:hover { text-decoration: underline; }

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
  .toolbar { flex-direction: column; align-items: stretch; }
  .cost-plaque { min-width: 76px; padding: 6px 10px; }
  .cost-num { font-size: 19px; }
  .row-desc { white-space: normal; }
  .row-arrow { display: none; }
}
</style>
