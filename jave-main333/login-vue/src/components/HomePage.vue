<template>
  <div class="home">
    <!-- 导航栏 -->
    <nav class="navbar">
      <div class="nav-brand">
        <span class="nav-mark">
          <svg viewBox="0 0 48 48" fill="none" stroke="#e8c66a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M24 4 40 14v20L24 44 8 34V14z" />
            <path d="M24 14 32 18v12l-8 4-8-4V18z" opacity=".7" />
            <circle cx="24" cy="24" r="3.4" fill="#e8c66a" stroke="none" />
          </svg>
        </span>
        <span class="nav-title">逆天魔宗</span>
      </div>

      <ul class="nav-links">
        <li
          v-for="item in navItems"
          :key="item.key"
          :class="{ active: item.key === activeNav }"
          @click="onNav(item)"
        >
          {{ item.label }}
        </li>
      </ul>

      <div class="nav-user">
        <span class="avatar">{{ avatarChar }}</span>
        <span class="uname">{{ username }}</span>
        <button class="logout" type="button" @click="emit('logout')">退 出</button>
      </div>
    </nav>

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
          <button class="search-btn" type="submit">搜 索</button>
        </div>
        <p v-if="searchError" class="search-hint search-error">{{ searchError }}</p>
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
          @click="quickSearch(c.id, c.name)"
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
      <p v-if="!resultList.length" class="empty">未寻得相关之物，换个词条试试</p>
      <ul v-else class="result-list">
        <li v-for="item in resultList" :key="item.id" class="result-row" @click="onEntry(item)">
          <span class="row-icon">{{ item.icon || '✦' }}</span>
          <div class="row-main">
            <h3>{{ item.title }}<small v-if="item.grade" class="grade">{{ item.grade }}</small></h3>
            <p>{{ item.description }}</p>
          </div>
          <span class="row-meta">{{ categoryNameById(item.categoryId) }}</span>
        </li>
      </ul>
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

    <footer class="home-foot">© 2026 逆天魔宗 · 堕魔者，永生不灭</footer>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useToast } from '../composables/useToast'
import { fetchHomeSummary, searchItems } from '../api/home'

const props = defineProps({
  username: {
    type: String,
    default: '道友'
  }
})

const emit = defineEmits(['logout'])

const { showToast } = useToast()

const activeNav = ref('home')
const query = ref('')
const searched = ref(false)
const lastQuery = ref('')
const searchCategoryId = ref(0)
const searchError = ref('')

const navItems = [
  { key: 'home', label: '首页' },
  { key: 'secret', label: '秘境' },
  { key: 'skill', label: '功法阁' },
  { key: 'rank', label: '宗门榜' },
  { key: 'forum', label: '论道' }
]

// 后端首页数据
const categories = ref([])
const hotItems = ref([])
const allCategories = ref([])
const resultList = ref([])
const resultTotal = ref(0)
const categoryCounts = ref({})

const avatarChar = computed(() => (props.username ? props.username.slice(0, 1).toUpperCase() : '道'))

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
    categoryCounts.value = data.categoryCounts || {}
    allCategories.value = flatten(categories.value)
  } catch (e) {
    showToast(e.message || '首页数据加载失败')
  }
}

onMounted(loadSummary)

async function doSearch(keyword, categoryId) {
  try {
    const data = await searchItems(keyword, categoryId || undefined)
    resultList.value = data.list || []
    resultTotal.value = data.total || 0
    searched.value = true
    searchError.value = ''
  } catch (e) {
    searched.value = false
    searchError.value = e.message || '检索失败'
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
  await doSearch(query.value, searchCategoryId.value)
}

async function quickSearch(categoryId, name) {
  searchCategoryId.value = categoryId
  query.value = ''
  lastQuery.value = `分类·${name}`
  await doSearch('', categoryId)
}

function clearSearch() {
  searched.value = false
  resultList.value = []
  resultTotal.value = 0
  searchCategoryId.value = 0
}

function onNav(item) {
  if (item.key === 'home') {
    activeNav.value = 'home'
    clearSearch()
    return
  }
  showToast(`「${item.label}」页面尚未开辟`)
}

function onEntry(entry) {
  showToast(`「${entry.title}」详情页待建设`)
}
</script>

<style scoped>
.home {
  width: 100%;
  max-width: 1120px;
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

/* ===== 导航栏 ===== */
.navbar {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 14px 28px;
  background:
    linear-gradient(120deg, rgba(200, 16, 46, .18), rgba(18, 10, 24, .6) 60%),
    var(--card-solid);
  border-bottom: 1px solid var(--border-strong);
}

.nav-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 700;
  letter-spacing: 3px;
  color: var(--gold-soft);
  flex-shrink: 0;
}

.nav-mark {
  width: 32px;
  height: 32px;
  border-radius: 9px;
  background: rgba(0, 0, 0, .35);
  border: 1px solid rgba(212, 175, 55, .55);
  display: grid;
  place-items: center;
  box-shadow: 0 0 16px rgba(212, 175, 55, .25);
}

.nav-mark svg { width: 18px; height: 18px; }
.nav-title { font-size: 16px; }

.nav-links {
  display: flex;
  align-items: center;
  gap: 4px;
  list-style: none;
  margin: 0;
  padding: 0;
  flex: 1;
}

.nav-links li {
  padding: 7px 14px;
  border-radius: 9px;
  font-size: 14px;
  letter-spacing: 2px;
  color: var(--text-soft);
  cursor: pointer;
  transition: color .18s, background .18s;
  user-select: none;
}

.nav-links li:hover {
  color: var(--gold-soft);
  background: rgba(212, 175, 55, .10);
}

.nav-links li.active {
  color: #f7e9c4;
  background: linear-gradient(135deg, rgba(140, 15, 29, .7), rgba(200, 16, 46, .55));
  box-shadow: 0 4px 16px rgba(200, 16, 46, .35), inset 0 0 10px rgba(0, 0, 0, .25);
}

.nav-user {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 14px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 1px solid var(--gold);
}

.uname {
  font-size: 13px;
  color: var(--text);
  letter-spacing: 1px;
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.logout {
  padding: 6px 12px;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, border-color .18s;
}

.logout:hover {
  color: var(--gold-soft);
  border-color: var(--gold);
}

/* ===== 主视觉 + 搜索 ===== */
.hero {
  padding: 34px 32px 28px;
  text-align: center;
  background:
    radial-gradient(120% 90% at 50% -20%, rgba(200, 16, 46, .24), transparent 60%),
    radial-gradient(80% 60% at 80% 120%, rgba(123, 15, 29, .26), transparent 60%);
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
  background: rgba(12, 8, 18, .55);
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
  background: rgba(12, 8, 18, .45);
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
  background: rgba(12, 8, 18, .45);
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
  .navbar { flex-wrap: wrap; gap: 12px; padding: 12px 18px; }
  .nav-links { order: 3; width: 100%; overflow-x: auto; flex-wrap: nowrap; }
  .nav-user { margin-left: auto; }
  .hero { padding: 26px 18px 22px; }
  .hero h1 { font-size: 20px; letter-spacing: 2px; }
  section { padding-left: 18px; padding-right: 18px; }
  .cat-chips { grid-template-columns: repeat(3, 1fr); }
  .hot-grid { grid-template-columns: 1fr; }
}

@media (max-width: 480px) {
  .cat-chips { grid-template-columns: repeat(2, 1fr); }
  .uname { display: none; }
  .row-meta { display: none; }
}
</style>
