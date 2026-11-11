<template>
  <div class="page">
    <SectNav active="secret" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 秘境名 -->
    <header class="hero">
      <span class="hero-seal">秘</span>
      <div>
        <h1>秘境</h1>
        <p class="hero-desc">{{ rootDesc }}</p>
      </div>
    </header>

    <!-- 探索入口 -->
    <section class="explore">
      <p class="explore-hint">吉凶自负，生死由天</p>
      <button class="explore-btn" type="button" :disabled="exploring" @click="onExplore">
        {{ exploring ? '探 索 中……' : '随 机 探 秘' }}
      </button>
    </section>

    <!-- 探索奇遇弹层 -->
    <div v-if="found" class="detail-mask" @click.self="found = null">
      <div class="detail-panel explore-panel">
        <button class="detail-close" type="button" @click="found = null">✕</button>
        <p class="explore-label">—— 天 机 引 导 ——</p>
        <div class="explore-head">
          <span class="explore-icon">{{ found.icon || '🗺️' }}</span>
          <div>
            <h2>{{ found.title }}<small v-if="found.grade" class="grade">{{ found.grade }}</small></h2>
            <p class="detail-crumb">{{ found.categoryName }} · 已有 {{ found.viewCount }} 道友探过</p>
          </div>
        </div>
        <p class="explore-text">{{ found.encounter }}</p>
        <p class="detail-desc">{{ found.description }}</p>
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

      <ul v-else class="list">
        <li v-for="item in list" :key="item.id" class="row" @click="openDetail(item)">
          <span class="row-icon">{{ item.icon || '🗺️' }}</span>
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

    <footer class="page-foot">© 2026 逆天魔宗 · 秘境 · 无尽机缘，待你开辟</footer>

    <!-- 详情弹层 -->
    <div v-if="detail" class="detail-mask" @click.self="closeDetail">
      <div class="detail-panel">
        <button class="detail-close" type="button" @click="closeDetail">✕</button>
        <div class="explore-head">
          <span class="explore-icon">{{ detail.icon || '🗺️' }}</span>
          <div>
            <h2>{{ detail.title }}<small v-if="detail.grade" class="grade">{{ detail.grade }}</small></h2>
            <p class="detail-crumb">{{ detail.categoryPath }}</p>
          </div>
        </div>
        <p v-if="detailLoading" class="empty">探查中……</p>
        <p v-else class="detail-desc">{{ detail.description }}</p>
        <p class="detail-meta">{{ detail.viewCount }} 人阅过</p>
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
import { fetchHomeSummary, fetchItemDetail, searchItems } from '../api/home'
import { fetchExplore } from '../api/sect'

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

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

// 探索
const exploring = ref(false)
const found = ref(null)

// 详情弹层
const detail = ref(null)
const related = ref([])
const detailLoading = ref(false)

let secretRootId = 0

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

/** 随机探秘：后端随机挑一个秘境并生成奇遇文案 */
async function onExplore() {
  exploring.value = true
  try {
    found.value = await fetchExplore()
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
  try {
    const d = await fetchItemDetail(entry.id)
    detail.value = d
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
  /* 半透明面板：全屏背景透出，内容靠自身卡片底色保证可读 */
  background: rgba(8, 5, 12, .20);
  border: 1px solid rgba(196, 154, 92, .18);
  border-radius: 22px;
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .06),
    0 24px 60px rgba(0, 0, 0, .50),
    0 0 50px rgba(200, 16, 46, .12);
}

/* ===== 秘境名 ===== */
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

/* ===== 探索入口 ===== */
.explore {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 6px 32px 26px;
}

.explore-hint {
  font-size: 12px;
  letter-spacing: 4px;
  color: rgba(226, 58, 78, .75);
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
.explore-btn:disabled { opacity: .7; cursor: wait; transform: none; }

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
.tab-count { font-size: 11px; color: var(--text-dim); letter-spacing: 0; }

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
  background: rgba(10, 7, 15, .78);
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
  .explore-btn { width: 100%; padding: 13px 0; }
}
</style>
