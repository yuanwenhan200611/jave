<template>
  <div class="home">
    <!-- 背景层：原图 16:10，按主页比例等比铺满，不裁切留白 -->
    <div class="home-bg" aria-hidden="true"></div>
    <div class="home-veil" aria-hidden="true"></div>

    <!-- 导航栏（共享组件：五个宗门页面统一使用） -->
    <SectNav active="home" :username="username" @nav="onNav" @logout="emit('logout')" />

    <!-- 主视觉 + 搜索 -->
    <header class="hero">
      <div class="hero-head">
        <span class="hero-seal">宗</span>
        <h1>恭迎 {{ username }} 道友归宗</h1>
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

    <!-- 分类导航 -->
    <section class="cats">
      <div class="section-head"><h2>分类导航</h2></div>
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

    <!-- 热门榜 -->
    <section class="hot">
      <div class="section-head"><h2>炙手可热</h2></div>
      <div class="hot-grid">
        <div
          v-for="(item, idx) in hotItems"
          :key="item.id"
          class="hot-card"
          @click="onEntry(item)"
        >
          <span class="rank" :class="{ top: idx < 3 }">{{ idx + 1 }}</span>
          <div class="hot-body">
            <h3>{{ item.title }}<small v-if="item.grade" class="grade">{{ item.grade }}</small></h3>
            <p>{{ item.description }}</p>
            <span class="hot-meta">{{ categoryNameById(item.categoryId) }} · {{ item.viewCount }} 阅</span>
          </div>
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
import { computed, onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import {
  fetchHomeSummary,
  fetchHotKeywords,
  fetchItemDetail,
  fetchRelatedItems,
  searchItems
} from '../api/home'

const props = defineProps({
  username: {
    type: String,
    default: '道友'
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
    allCategories.value = flatten(categories.value)
  } catch (e) {
    showToast(e.message || '首页数据加载失败')
  }
}

async function loadHotKeywords() {
  try {
    hotKeywords.value = (await fetchHotKeywords(8, 30)) || []
  } catch {
    hotKeywords.value = []
  }
}

onMounted(() => {
  loadSummary()
  loadHotKeywords()
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
      size: pageSize.value
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
  background: var(--card);
  border: 1px solid var(--border-strong);
  border-radius: 22px;
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .10),
    0 30px 80px rgba(0, 0, 0, .65),
    0 0 60px rgba(200, 16, 46, .18);
  backdrop-filter: blur(6px);
}

/* ===== 背景图 =====
   原图 1728×1080（严格 16:10）。
   主图用 contain 完整呈现（画面主体不裁切、不变形）；
   面板宽高比与 16:10 有偏差时，空隙由底层同图放大模糊补满，视觉无缝。 */
.home-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  overflow: hidden;
}

/* 底层：同一张图 cover + 模糊，填满比例不一致留下的空隙 */
.home-bg::before {
  content: "";
  position: absolute;
  inset: -8%;
  background-image: url('../assets/home-bg.jpg');
  background-size: cover;
  background-position: center;
  filter: blur(26px) brightness(.40) saturate(1.15);
  transform: scale(1.08);
}

/* 主图：contain 完整显示，绝不裁切 */
.home-bg::after {
  content: "";
  position: absolute;
  inset: 0;
  background-image: url('../assets/home-bg.jpg');
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  /* 尽量保留原图亮度与清晰度，仅做轻微压暗以托住前景文字 */
  filter: brightness(.94) saturate(1.06) contrast(1.04);
}

/* 可读性遮罩：单独一层，避免与图片层抢 ::before / ::after。
   只在首屏（导航 + 标题 + 搜索）稍重，下方大面积留清晰；
   文字可读性主要靠卡片自身的半透明底色来保证。 */
.home-veil {
  position: absolute;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  background:
    linear-gradient(180deg,
      rgba(10, 7, 16, .62) 0%,
      rgba(10, 7, 16, .30) 18%,
      rgba(10, 7, 16, .10) 34%,
      rgba(10, 7, 16, .12) 62%,
      rgba(10, 7, 16, .48) 88%,
      rgba(10, 7, 16, .72) 100%);
}

/* 前景所有区块需压在背景层之上 */
.home > :not(.home-bg):not(.home-veil) {
  position: relative;
  z-index: 1;
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

.hero h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 26px;
  font-weight: 700;
  letter-spacing: 4px;
  color: #f3e8d6;
  text-shadow: 0 2px 18px rgba(200, 16, 46, .45);
  margin: 0;
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
  background: rgba(12, 8, 18, .66);
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

/* ===== 热门榜 ===== */
.hot { border-top: 1px solid var(--border); padding-top: 18px; }

.hot-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px 14px;
}

.hot-card {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(12, 8, 18, .66);
  cursor: pointer;
  transition: border-color .18s, background .18s;
}

.hot-card:hover {
  border-color: var(--gold);
  background: rgba(28, 18, 36, .65);
}

.rank {
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

.rank.top {
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border-color: var(--gold);
  box-shadow: 0 0 10px rgba(200, 16, 46, .4);
}

.hot-body { flex: 1; min-width: 0; }

.hot-body h3 {
  font-size: 15px;
  color: #f3e8d6;
  letter-spacing: 1px;
  margin: 0 0 4px;
}

.hot-body p {
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
@media (max-width: 780px) {
  .hero { padding: 26px 18px 22px; }
  .hero h1 { font-size: 20px; letter-spacing: 2px; }
  section { padding-left: 18px; padding-right: 18px; }
  .cat-chips { grid-template-columns: repeat(3, 1fr); }
  .hot-grid { grid-template-columns: 1fr; }

  /* 窄屏面板很高，图片若还 contain 会被压成一条细带；
     改为 cover 铺满，视觉更有冲击力 */
  .home-bg::after {
    background-size: cover;
    filter: brightness(.86) saturate(1.06);
  }
  .home-bg::before {
    filter: blur(30px) brightness(.35) saturate(1.1);
  }
  /* 移动端卡片底色再实一点，保证小字可读 */
  .cat-chip,
  .hot-card,
  .result-row { background: rgba(12, 8, 18, .82); }
}


@media (max-width: 480px) {
  .cat-chips { grid-template-columns: repeat(2, 1fr); }
  .row-meta { display: none; }
}
</style>
