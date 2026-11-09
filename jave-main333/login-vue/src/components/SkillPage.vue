<template>
  <div class="page">
    <div class="page-bg" aria-hidden="true"></div>

    <SectNav active="skill" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 阁名 + 背景 -->
    <header class="hero">
      <span class="hero-seal">功</span>
      <div>
        <h1>功法阁</h1>
        <p class="hero-desc">{{ rootDesc }}</p>
      </div>
    </header>

    <!-- 种类分堂 -->
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
      <p v-else-if="!loading && !list.length" class="empty">此阁暂未收录功法，另择高就</p>

      <ul v-else class="list">
        <li v-for="item in list" :key="item.id" class="row" @click="openDetail(item)">
          <span class="row-icon">{{ item.icon || '📜' }}</span>
          <div class="row-main">
            <h3>{{ item.title }}<small v-if="item.grade" class="grade">{{ item.grade }}</small></h3>
            <p>{{ item.description }}</p>
          </div>
          <span class="row-meta">{{ item.categoryName }} · {{ item.viewCount }} 阅</span>
        </li>
      </ul>

      <div v-if="pages > 1" class="pager">
        <button type="button" class="pager-btn" :disabled="page <= 1" @click="gotoPage(page - 1)">上一页</button>
        <span class="pager-info">第 {{ page }} / {{ pages }} 页</span>
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
            <h2>{{ detail.title }}<small v-if="detail.grade" class="grade">{{ detail.grade }}</small></h2>
            <p class="detail-crumb">{{ detail.categoryPath }}</p>
          </div>
        </div>
        <p v-if="detailLoading" class="empty">翻阅中……</p>
        <p v-else class="detail-desc">{{ detail.description }}</p>
        <p class="detail-meta">{{ detail.viewCount }} 人参悟</p>
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

/** 功法顶级分类 id（含子孙计数） */
let skillRootId = 0

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
</script>

<style scoped>
.page {
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

/* 背景图：模糊铺满，压暗托文字 */
.page-bg {
  position: absolute;
  inset: -8%;
  z-index: 0;
  background-image: url('../assets/home-bg.jpg');
  background-size: cover;
  background-position: center;
  filter: blur(30px) brightness(.30) saturate(1.1);
}

.page > :not(.page-bg) {
  position: relative;
  z-index: 1;
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

/* ===== 分堂 tab ===== */
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
  padding: 8px 18px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(12, 8, 18, .72);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 14px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s;
}

.tab:hover { color: var(--gold-soft); border-color: var(--gold); }

.tab.active {
  color: #f7e9c4;
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .7), rgba(200, 16, 46, .5));
  box-shadow: 0 0 14px rgba(200, 16, 46, .3);
}

.tab-icon { font-size: 15px; }

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

/* ===== 列表 ===== */
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
  background: rgba(12, 8, 18, .66);
  cursor: pointer;
  transition: background .15s;
}

.row + .row { border-top: 1px solid var(--border); }
.row:hover { background: rgba(28, 18, 36, .65); }

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
  .hero { padding: 26px 18px 18px; }
  .hero h1 { font-size: 21px; letter-spacing: 2px; }
  .tabs-wrap { padding: 0 18px 20px; }
  .row-meta { display: none; }
}
</style>
