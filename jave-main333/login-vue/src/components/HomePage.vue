<template>
  <div class="home">
    <!-- 背景已提升为全站全屏背景（见 styles/global.css 的 body::before/::after） -->

    <!-- 导航栏（共享组件：五个宗门页面统一使用） -->
    <SectNav active="home" :username="username" @nav="onNav" @logout="emit('logout')" />

    <!-- 主视觉 + 搜索 -->
    <header class="hero">
      <div class="hero-head">
        <span class="hero-seal">宗</span>
        <div class="hero-title">
          <h1>恭迎 {{ username }} 道友归宗</h1>
          <p v-if="totalItems" class="hero-sub">
            宗门典藏 {{ totalItems }} 卷 · {{ topCategories.length }} 类道藏 · 今日亦当精进魔功
          </p>
        </div>
      </div>

      <form class="search" novalidate @submit.prevent="onSearch">
        <div class="search-box">
          <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="7" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            v-model.trim="query"
            type="text"
            class="search-input"
            placeholder="检索功法、秘境、丹药、法宝……"
          >
          <button v-if="query" class="search-clear" type="button" title="清空关键词" @click="query = ''">✕</button>
          <select v-model="searchCategoryId" class="search-cat">
            <option :value="0">全部分类</option>
            <option v-for="cat in flatCategories" :key="cat.id" :value="cat.id">
              {{ cat.prefix }}{{ cat.name }}
            </option>
          </select>
          <button class="search-btn" type="submit" :disabled="searchLoading">
            {{ searchLoading ? '搜寻中' : '搜 索' }}
          </button>
        </div>
        <p v-if="searchError" class="search-hint search-error">{{ searchError }}</p>

        <!-- 热搜词 -->
        <div v-if="hotKeywords.length" class="hot-words">
          <span class="hot-words-label">热门词条</span>
          <button
            v-for="w in hotKeywords"
            :key="w.keyword"
            type="button"
            class="hot-word"
            @click="clickKeyword(w.keyword)"
          >{{ w.keyword }}</button>
        </div>
      </form>
    </header>

    <!-- 个人修行速览 + 宗门各堂快捷入口 -->
    <section class="overview">
      <div class="overview-panel">
        <div class="section-head">
          <h2>修行速览</h2>
          <span class="section-extra link" @click="onNav('profile')">洞府详情 →</span>
        </div>
        <div class="mini-stats">
          <div class="mini-stat">
            <span class="mini-label">境界</span>
            <b>{{ myFullRealm }}</b>
            <small>修为 {{ myStats.cultivation || 0 }}</small>
          </div>
          <div class="mini-stat">
            <span class="mini-label">可用灵石</span>
            <b>{{ myStats.stonesAvailable ?? 0 }}</b>
            <small>累计 {{ myStats.stonesTotal || 0 }}</small>
          </div>
          <div class="mini-stat">
            <span class="mini-label">可用贡献</span>
            <b>{{ myStats.contributionAvailable ?? 0 }}</b>
            <small>累计 {{ myStats.contributionTotal || 0 }}</small>
          </div>
          <div class="mini-stat">
            <span class="mini-label">任务功勋</span>
            <b>{{ myStats.questDone || 0 }}</b>
            <small>进行中 {{ myStats.questActive || 0 }}</small>
          </div>
          <div class="mini-stat">
            <span class="mini-label">已习功法</span>
            <b>{{ myStats.skillCount || 0 }}</b>
            <small>已辟秘境 {{ myStats.secretCount || 0 }}</small>
          </div>
        </div>
      </div>

      <div class="overview-panel">
        <div class="section-head">
          <h2>宗门速达</h2>
          <span class="section-extra">一键直达各堂</span>
        </div>
        <div class="quick-grid">
          <button
            v-for="q in quickEntries"
            :key="q.key"
            type="button"
            class="quick-item"
            @click="onNav(q.key)"
          >
            <span class="quick-icon">{{ q.icon }}</span>
            <span>{{ q.label }}</span>
          </button>
        </div>
      </div>
    </section>

    <!-- 分类导航 -->
    <section class="cats">
      <div class="section-head">
        <h2>分类导航</h2>
        <span class="section-extra">点选分类，快速求索</span>
      </div>
      <div class="cat-chips">
        <button
          v-for="c in topCategories"
          :key="c.id"
          type="button"
          class="cat-chip"
          :class="{ active: searchCategoryId === c.id && searched }"
          @click="quickSearch(c.id)"
        >
          <span class="cat-icon">{{ c.icon }}</span>
          <span class="cat-name">{{ c.name }}</span>
          <span class="cat-count">{{ c.count }}</span>
        </button>
      </div>
    </section>

    <!-- 检索结果 -->
    <section v-if="searched" class="results">
      <div class="section-head">
        <h2>检索「{{ lastQuery }}」</h2>
        <span class="section-extra">{{ resultTotal }} 条
          <button class="clear-btn" type="button" @click="clearSearch">清空</button>
        </span>
      </div>

      <!-- 排序 -->
      <div class="sort-bar">
        <button
          v-for="s in sortOptions"
          :key="s.value"
          type="button"
          class="sort-btn"
          :class="{ active: searchSort === s.value }"
          @click="changeSort(s.value)"
        >{{ s.label }}</button>
      </div>

      <p v-if="!resultList.length" class="empty">未寻得相关之物，换个词条试试</p>
      <ul v-else class="result-list">
        <li v-for="item in resultList" :key="item.id" class="result-row" @click="onEntry(item)">
          <span class="row-icon">{{ item.icon || '✦' }}</span>
          <div class="row-main">
            <h3>{{ item.title }}<small v-if="item.grade" class="grade">{{ item.grade }}</small></h3>
            <p>{{ item.description }}</p>
          </div>
          <span class="row-meta">{{ item.categoryName || categoryNameById(item.categoryId) }}</span>
        </li>
      </ul>

      <!-- 后端分页 -->
      <div v-if="pages > 1" class="pager">
        <button type="button" class="pager-btn" :disabled="page <= 1" @click="gotoPage(page - 1)">上一页</button>
        <span class="pager-info">第 {{ page }} / {{ pages }} 页</span>
        <button type="button" class="pager-btn" :disabled="page >= pages" @click="gotoPage(page + 1)">下一页</button>
      </div>
    </section>

    <!-- 热门榜 + 最新收录（数据均来自 /api/home/summary） -->
    <section class="discover">
      <div class="discover-panel">
        <div class="section-head">
          <h2>炙手可热</h2>
          <span class="section-extra">浏览量 TOP 6</span>
        </div>
        <div class="discover-list">
          <div
            v-for="(item, idx) in hotItems.slice(0, 6)"
            :key="item.id"
            class="discover-card"
            @click="onEntry(item)"
          >
            <span class="rank" :class="{ top: idx < 3 }">{{ idx + 1 }}</span>
            <div class="discover-body">
              <h3>{{ item.title }}<small v-if="item.grade" class="grade">{{ item.grade }}</small></h3>
              <p>{{ item.description }}</p>
              <span class="hot-meta">{{ categoryNameById(item.categoryId) }} · {{ item.viewCount || 0 }} 阅</span>
            </div>
          </div>
          <p v-if="!hotItems.length" class="empty">宗门尚无热门卷宗</p>
        </div>
      </div>

      <div class="discover-panel">
        <div class="section-head">
          <h2>新入藏</h2>
          <span class="section-extra">最近收录 TOP 6</span>
        </div>
        <div class="discover-list">
          <div
            v-for="(item, idx) in latestItems.slice(0, 6)"
            :key="item.id"
            class="discover-card"
            @click="onEntry(item)"
          >
            <span class="new-mark" :class="{ fresh: idx < 2 }">{{ idx < 2 ? '新' : '✦' }}</span>
            <div class="discover-body">
              <h3>{{ item.title }}<small v-if="item.grade" class="grade">{{ item.grade }}</small></h3>
              <p>{{ item.description }}</p>
              <span class="hot-meta">{{ categoryNameById(item.categoryId) }}</span>
            </div>
          </div>
          <p v-if="!latestItems.length" class="empty">暂无新入藏卷宗</p>
        </div>
      </div>
    </section>

    <!-- 条目详情弹层：数据来自后端 GET /api/home/item/{id}（同时浏览量 +1） -->
    <div v-if="detail" class="detail-mask" @click.self="closeDetail">
      <div class="detail-panel">
        <button class="detail-close" type="button" @click="closeDetail">✕</button>
        <div class="detail-head">
          <span class="detail-icon">{{ detail.icon || '✦' }}</span>
          <div>
            <h2>{{ detail.title }}<small v-if="detail.grade" class="grade">{{ detail.grade }}</small></h2>
            <p class="detail-crumb">{{ detail.categoryPath }}</p>
          </div>
        </div>
        <p v-if="detailLoading" class="empty">探查中……</p>
        <p v-else class="detail-desc">{{ detail.description }}</p>
        <p class="detail-meta">{{ detail.viewCount }} 人阅过</p>

        <div v-if="related.length" class="detail-related">
          <h3>同类之物</h3>
          <div class="related-chips">
            <button
              v-for="r in related"
              :key="r.id"
              type="button"
              class="related-chip"
              @click="onEntry(r)"
            >{{ r.icon || '✦' }} {{ r.title }}</button>
          </div>
        </div>
      </div>
    </div>

    <footer class="home-foot">© 2026 逆天魔宗 · 堕魔者，永生不灭</footer>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import { fetchProfile } from '../api/profile'
import {
  fetchHomeSummary,
  fetchHotKeywords,
  fetchItemDetail,
  fetchRelatedItems,
  searchItems
} from '../api/home'
import { fullRealm, stageOf } from '../utils/realm'

const props = defineProps({
  username: {
    type: String,
    default: '道友'
  },
  // 洞府「再寻一次」联动：父组件传入关键词，自动执行一次搜索
  searchSeed: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const activeNav = ref('home')
const query = ref('')
const searched = ref(false)
const lastQuery = ref('')
const searchCategoryId = ref(0)
const searchError = ref('')
const searchSort = ref('hot')
const searchLoading = ref(false)

// 分页（后端分页，total/pages 由接口返回）
const page = ref(1)
const pageSize = ref(10)
const total = ref(0)
const pages = ref(0)

// 热词
const hotKeywords = ref([])

const sortOptions = [
  { value: 'hot', label: '最热' },
  { value: 'new', label: '最新' },
  { value: 'grade', label: '品阶' },
  { value: 'title', label: '名称' }
]

// 详情弹层
const detail = ref(null)
const related = ref([])
const detailLoading = ref(false)

// 导航项定义已移至 SectNav.vue

// 后端首页数据
const categories = ref([])
const hotItems = ref([])
const latestItems = ref([])
const allCategories = ref([])
const resultList = ref([])
const resultTotal = computed(() => total.value)
const categoryCounts = ref({})
const totalItems = ref(0)

// 个人修行速览（复用洞府接口，失败时静默降级为 0，不影响首页浏览）
const profileInfo = ref({})
const myStats = ref({})

/** 完整境界：大境界 + 按修为折算的小层次 */
const myFullRealm = computed(() =>
  fullRealm(profileInfo.value.realm || '炼气', stageOf(profileInfo.value.realm || '炼气', myStats.value.cultivation || 0))
)

// 宗门速达：与 SectNav 的视图 key 保持一致
const quickEntries = [
  { key: 'secret', label: '秘境', icon: '🗺️' },
  { key: 'skill', label: '功法阁', icon: '📖' },
  { key: 'cultivation', label: '魔功殿', icon: '🔥' },
  { key: 'quest', label: '任务阁', icon: '🗡️' },
  { key: 'market', label: '坊市', icon: '💰' },
  { key: 'rank', label: '宗门榜', icon: '🏆' },
  { key: 'forum', label: '血辩台', icon: '📜' },
  { key: 'profile', label: '洞府', icon: '🏠' }
]

// 顶级分类（分类导航用，条目数来自后端聚合）
const topCategories = computed(() =>
  categories.value.map(c => ({
    id: c.id,
    name: c.name,
    icon: c.icon || '✦',
    count: categoryCounts.value[c.id] || 0
  }))
)

// 展平分类树
function flatten(nodes, acc = []) {
  for (const n of nodes) {
    acc.push(n)
    if (n.children?.length) flatten(n.children, acc)
  }
  return acc
}

// 展平分类树，用于搜索下拉（带缩进前缀体现分级）
const flatCategories = computed(() => {
  const list = []
  const walk = (nodes, depth) => {
    for (const n of nodes) {
      list.push({ id: n.id, name: n.name, prefix: '　'.repeat(depth) + (depth ? '└ ' : '') })
      if (n.children?.length) walk(n.children, depth + 1)
    }
  }
  walk(categories.value, 0)
  return list
})

const categoryNameById = computed(() => (id) => {
  const c = allCategories.value.find(c => c.id === id)
  return c ? c.name : '未分类'
})

async function loadSummary() {
  try {
    const data = await fetchHomeSummary()
    categories.value = data.categories || []
    hotItems.value = data.hotItems || []
    latestItems.value = data.latestItems || []
    categoryCounts.value = data.categoryCounts || {}
    totalItems.value = data.totalItems || 0
    allCategories.value = flatten(categories.value)
  } catch (e) {
    showToast(e.message || '首页数据加载失败')
  }
}

async function loadProfile() {
  if (!props.username) return
  try {
    const data = await fetchProfile(props.username)
    profileInfo.value = data.profile || {}
    myStats.value = data.stats || {}
  } catch {
    // 个人数据取不到时保持默认 0，首页其余功能照常可用
  }
}

async function loadHotKeywords() {
  try {
    hotKeywords.value = (await fetchHotKeywords(8, 30)) || []
  } catch {
    hotKeywords.value = []
  }
}

// 详情弹层：Esc 关闭 + 打开时锁定页面滚动
function onKeydown(e) {
  if (e.key === 'Escape' && detail.value) closeDetail()
}

watch(detail, (v) => {
  document.body.style.overflow = v ? 'hidden' : ''
})

onMounted(() => {
  loadSummary()
  loadHotKeywords()
  loadProfile()
  window.addEventListener('keydown', onKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', onKeydown)
  document.body.style.overflow = ''
})

// 洞府「再寻一次」：父组件改变 searchSeed 时自动搜索
watch(() => props.searchSeed, (kw) => {
  if (!kw) return
  query.value = kw
  searchCategoryId.value = 0
  searched.value = true
  lastQuery.value = kw
  doSearch({ keyword: kw, categoryId: 0, toPage: 1 })
})

/**
 * 统一走后端分页搜索。
 * 后端会返回 list / total / page / size / pages，前端不再本地切片。
 */
async function doSearch({ keyword = '', categoryId = 0, sort = searchSort.value, toPage = 1 } = {}) {
  searchLoading.value = true
  try {
    const data = await searchItems({
      keyword,
      categoryId: categoryId || undefined,
      sort,
      page: toPage,
      size: pageSize.value,
      // 搜索足迹联动：带上当前登录用户，后端落 search_log.username
      username: props.username
    })
    resultList.value = data.list || []
    total.value = data.total || 0
    pages.value = data.pages || 0
    page.value = data.page || toPage
    searched.value = true
    searchError.value = ''
  } catch (e) {
    searched.value = false
    searchError.value = e.message || '检索失败'
  } finally {
    searchLoading.value = false
  }
}

async function onSearch() {
  if (!query.value && !searchCategoryId.value) {
    showToast('请输入检索词条或选择分类')
    return
  }
  const catName = searchCategoryId.value
    ? (flatCategories.value.find(c => c.id === searchCategoryId.value)?.name || '')
    : ''
  lastQuery.value = [query.value, catName && `分类·${catName}`].filter(Boolean).join(' / ')
  await doSearch({ keyword: query.value, categoryId: searchCategoryId.value, toPage: 1 })
  // 搜索后刷新热词（这次搜索已被后端记入日志）
  loadHotKeywords()
}

async function quickSearch(categoryId) {
  searchCategoryId.value = categoryId
  query.value = ''
  const name = flatCategories.value.find(c => c.id === categoryId)?.name || ''
  lastQuery.value = `分类·${name}`
  await doSearch({ keyword: '', categoryId, toPage: 1 })
}

async function changeSort(sort) {
  if (searchSort.value === sort) return
  searchSort.value = sort
  if (searched.value) {
    await doSearch({ keyword: query.value, categoryId: searchCategoryId.value, sort, toPage: 1 })
  }
}

async function gotoPage(p) {
  if (p < 1 || p > pages.value || p === page.value) return
  await doSearch({
    keyword: query.value,
    categoryId: searchCategoryId.value,
    sort: searchSort.value,
    toPage: p
  })
}

function clickKeyword(word) {
  query.value = word
  searchCategoryId.value = 0
  lastQuery.value = word
  doSearch({ keyword: word, categoryId: 0, toPage: 1 })
}

function clearSearch() {
  searched.value = false
  resultList.value = []
  total.value = 0
  pages.value = 0
  page.value = 1
  searchCategoryId.value = 0
}

/** 顶部导航：key 为 'home' 时留在本页，其余交给 App.vue 切换到对应宗门页面 */
function onNav(key) {
  if (key === 'home') {
    activeNav.value = 'home'
    clearSearch()
    return
  }
  emit('nav', key)
}

/** 打开详情弹层：后端 GET /item/{id} 会顺带把浏览量 +1 */
async function onEntry(entry) {
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

</script>

<style scoped>
.home {
  position: relative;
  width: 100%;
  max-width: 1320px;
  margin: 0 auto;
  /* 半透明面板：让全屏背景透出来，前景内容靠自身遮罩与卡片底色保证可读 */
  background: rgba(8, 5, 12, .20);
  border: 1px solid rgba(196, 154, 92, .18);
  border-radius: 22px;
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .06),
    0 24px 60px rgba(0, 0, 0, .50),
    0 0 50px rgba(200, 16, 46, .12);
}

/* ===== 主视觉 + 搜索 ===== */
.hero {
  padding: 34px 32px 28px;
  text-align: center;
  background:
    radial-gradient(120% 90% at 50% -20%, rgba(200, 16, 46, .28), transparent 62%),
    linear-gradient(180deg, rgba(10, 7, 16, .30), rgba(10, 7, 16, .55));
}

.hero-head {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
}

.hero-seal {
  width: 46px;
  height: 46px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 28px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 2px solid var(--gold);
  box-shadow: 0 4px 18px rgba(200, 16, 46, .5), inset 0 0 10px rgba(0, 0, 0, .35);
  transform: rotate(-6deg);
  flex-shrink: 0;
}

.hero-title { text-align: left; }

.hero h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 26px;
  font-weight: 700;
  letter-spacing: 4px;
  color: #f3e8d6;
  text-shadow: 0 2px 18px rgba(200, 16, 46, .45);
  margin: 0;
}

.hero-sub {
  margin-top: 6px;
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(212, 175, 55, .68);
}

.search {
  margin: 24px auto 0;
  max-width: 640px;
}

.search-box {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 6px 6px 16px;
  background: var(--card-input);
  border: 1px solid var(--border-strong);
  border-radius: 14px;
  box-shadow: 0 0 0 1px rgba(212, 175, 55, .08), 0 10px 30px rgba(0, 0, 0, .45);
  transition: border-color .18s, box-shadow .18s;
}

.search-box:focus-within {
  border-color: var(--gold);
  box-shadow: 0 0 0 4px rgba(200, 16, 46, .18), 0 0 18px rgba(212, 175, 55, .20);
}

.search-icon {
  width: 20px;
  height: 20px;
  color: var(--text-dim);
  flex-shrink: 0;
}

.search-clear {
  width: 26px;
  height: 26px;
  border: 0;
  border-radius: 50%;
  background: rgba(212, 175, 55, .12);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  cursor: pointer;
  flex-shrink: 0;
  transition: color .18s, background .18s;
}

.search-clear:hover { color: #f7e9c4; background: rgba(200, 16, 46, .4); }

.search-input {
  flex: 1;
  min-width: 0;
  height: 42px;
  border: 0;
  background: transparent;
  outline: none;
  font-family: inherit;
  font-size: 15px;
  color: var(--text);
}

.search-input::placeholder { color: var(--text-dim); }

.search-cat {
  height: 42px;
  border: 1px solid var(--border-strong);
  border-radius: 10px;
  background: rgba(12, 8, 18, .8);
  color: var(--text);
  font-family: inherit;
  font-size: 13px;
  padding: 0 8px;
  cursor: pointer;
  flex-shrink: 0;
}

.search-btn {
  height: 42px;
  padding: 0 24px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 10px;
  cursor: pointer;
  background: linear-gradient(135deg, #8c0f1d 0%, #c8102e 55%, #e23a4e 100%);
  color: #f7e9c4;
  font-family: inherit;
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 4px;
  box-shadow: 0 4px 18px rgba(200, 16, 46, .4), inset 0 0 10px rgba(0, 0, 0, .3);
  transition: transform .15s, filter .2s;
  flex-shrink: 0;
}

.search-btn:hover { transform: translateY(-1px); filter: brightness(1.12); }
.search-btn:active { transform: translateY(0); }

.search-hint {
  margin-top: 10px;
  font-size: 13px;
  letter-spacing: 1px;
  color: var(--text-soft);
}

.search-error { color: #e23a4e; }

/* ===== 通用区块头 ===== */
section { padding: 6px 32px 22px; }

.section-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 14px;
}

.section-head h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 19px;
  font-weight: 700;
  letter-spacing: 3px;
  color: var(--gold-soft);
  margin: 0;
}

.section-extra {
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
}

.clear-btn {
  margin-left: 10px;
  padding: 2px 10px;
  border: 1px solid var(--border-strong);
  border-radius: 999px;
  background: transparent;
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  cursor: pointer;
  transition: color .18s, border-color .18s;
}

.clear-btn:hover { color: var(--gold-soft); border-color: var(--gold); }

.section-extra.link { cursor: pointer; transition: color .18s; }
.section-extra.link:hover { color: var(--gold-soft); }

/* ===== 修行速览 + 宗门速达 ===== */
.overview {
  display: grid;
  grid-template-columns: 1.25fr 1fr;
  gap: 14px;
  padding: 0 32px 6px;
}

.overview-panel {
  padding: 16px 18px 18px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background:
    radial-gradient(120% 90% at 0% 0%, rgba(200, 16, 46, .12), transparent 65%),
    rgba(10, 7, 15, .78);
}

.overview-panel .section-head { margin-bottom: 12px; }

.mini-stats {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 8px;
}

.mini-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 10px 4px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: rgba(12, 8, 18, .65);
  text-align: center;
}

.mini-label {
  font-size: 11px;
  letter-spacing: 1px;
  color: var(--text-dim);
  white-space: nowrap;
}

.mini-stat b {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 20px;
  line-height: 1.2;
  color: var(--gold-soft);
}

.mini-stat small {
  font-size: 10px;
  color: var(--text-dim);
  letter-spacing: .5px;
  white-space: nowrap;
}

.quick-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 8px;
}

.quick-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 9px 4px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: rgba(12, 8, 18, .65);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  cursor: pointer;
  transition: transform .15s, border-color .18s, color .18s, background .18s;
}

.quick-item:hover {
  transform: translateY(-2px);
  border-color: var(--gold);
  color: var(--gold-soft);
  background: rgba(28, 18, 36, .75);
}

.quick-icon { font-size: 19px; line-height: 1; }

/* ===== 分类导航 ===== */
.cats { padding-top: 18px; }

.cat-chips {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 10px;
}

.cat-chip {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 14px 8px 12px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(12, 8, 18, .72);
  cursor: pointer;
  font-family: inherit;
  transition: transform .15s, border-color .18s, background .18s;
}

.cat-chip:hover {
  transform: translateY(-2px);
  border-color: var(--gold);
  background: rgba(28, 18, 36, .7);
}

.cat-chip.active {
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .45), rgba(200, 16, 46, .3));
  box-shadow: 0 0 14px rgba(200, 16, 46, .3);
}

.cat-icon { font-size: 22px; line-height: 1; }

.cat-name {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 15px;
  letter-spacing: 2px;
  color: var(--gold-soft);
}

.cat-count { font-size: 11px; color: var(--text-dim); letter-spacing: 1px; }

/* ===== 检索结果：紧凑列表 ===== */
.results { border-top: 1px solid var(--border); padding-top: 18px; }

.empty {
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
  padding: 18px 0;
}

.result-list {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
}

.result-row {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 16px;
  background: rgba(10, 7, 15, .78);
  cursor: pointer;
  transition: background .15s;
}

.result-row + .result-row { border-top: 1px solid var(--border); }
.result-row:hover { background: rgba(28, 18, 36, .65); }

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

.row-meta {
  font-size: 12px;
  color: rgba(212, 175, 55, .6);
  letter-spacing: 1px;
  flex-shrink: 0;
}

.grade {
  display: inline-block;
  margin-left: 8px;
  padding: 1px 8px;
  font-size: 11px;
  border-radius: 999px;
  color: #f7e9c4;
  background: linear-gradient(135deg, rgba(140, 15, 29, .8), rgba(200, 16, 46, .6));
  border: 1px solid rgba(212, 175, 55, .4);
  vertical-align: middle;
}

/* ===== 热门榜 + 新入藏 ===== */
.discover {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  border-top: 1px solid var(--border);
  padding-top: 18px;
}

.discover-panel {
  padding: 14px 16px 16px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: rgba(10, 7, 15, .62);
}

.discover-list { display: flex; flex-direction: column; gap: 8px; }

.discover-card {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 10px 12px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: rgba(12, 8, 18, .72);
  cursor: pointer;
  transition: border-color .18s, background .18s;
}

.discover-card:hover {
  border-color: var(--gold);
  background: rgba(28, 18, 36, .7);
}

.rank,
.new-mark {
  width: 24px;
  height: 24px;
  border-radius: 7px;
  display: grid;
  place-items: center;
  font-size: 12px;
  font-weight: 700;
  color: var(--text-soft);
  background: rgba(212, 175, 55, .10);
  border: 1px solid var(--border-strong);
  flex-shrink: 0;
  margin-top: 2px;
}

.rank.top,
.new-mark.fresh {
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border-color: var(--gold);
  box-shadow: 0 0 10px rgba(200, 16, 46, .4);
}

.discover-body { flex: 1; min-width: 0; }

.discover-body h3 {
  font-size: 15px;
  color: #f3e8d6;
  letter-spacing: 1px;
  margin: 0 0 4px;
}

.discover-body p {
  font-size: 13px;
  line-height: 1.6;
  color: var(--text-soft);
  margin: 0 0 6px;
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.hot-meta { font-size: 12px; color: rgba(212, 175, 55, .6); letter-spacing: 1px; }

/* ===== 热搜词 ===== */
.hot-words {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 14px;
}

.hot-words-label {
  font-size: 12px;
  letter-spacing: 2px;
  color: rgba(212, 175, 55, .65);
}

.hot-word {
  padding: 3px 11px;
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

.hot-word:hover {
  color: var(--gold-soft);
  border-color: var(--gold);
  background: rgba(200, 16, 46, .18);
}

/* ===== 排序条 ===== */
.sort-bar {
  display: flex;
  gap: 6px;
  margin-bottom: 12px;
}

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

.search-btn:disabled { opacity: .7; cursor: wait; transform: none; }

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

/* ===== 页脚 ===== */
.home-foot {
  padding: 16px 32px 20px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .5);
  border-top: 1px solid var(--border);
}

/* ===== 响应式 ===== */
@media (max-width: 980px) {
  .overview,
  .discover { grid-template-columns: 1fr; }
}

@media (max-width: 780px) {
  .hero { padding: 26px 18px 22px; }
  .hero h1 { font-size: 20px; letter-spacing: 2px; }
  section { padding-left: 18px; padding-right: 18px; }
  .cat-chips { grid-template-columns: repeat(3, 1fr); }
  .mini-stats { grid-template-columns: repeat(3, 1fr); }

  /* 移动端面板底色再实一点，保证小字可读 */
  .home { background: rgba(8, 5, 12, .62); }
  .cat-chip,
  .discover-card,
  .result-row { background: rgba(12, 8, 18, .82); }
}


@media (max-width: 480px) {
  .cat-chips { grid-template-columns: repeat(2, 1fr); }
  .mini-stats { grid-template-columns: repeat(2, 1fr); }
  .mini-stat:last-child { grid-column: span 2; }
  .quick-grid { grid-template-columns: repeat(4, 1fr); }
  .quick-item { font-size: 11px; letter-spacing: 0; }
  .hero-sub { font-size: 11px; letter-spacing: 1px; }
  .row-meta { display: none; }
}
</style>
