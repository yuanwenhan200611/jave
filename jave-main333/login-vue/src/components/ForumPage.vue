<template>
  <div class="page">
    <SectNav active="forum" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 堂名 -->
    <header class="hero">
      <span class="hero-seal">辩</span>
      <div>
        <h1>血 辩 台</h1>
        <p class="hero-desc">以魔会友，以力服人 · 驳倒道友者，吞其道韵</p>
      </div>
    </header>

    <!-- 我的道行 -->
    <section class="self-bar">
      <span class="self-item"><i>境界</i><b>{{ meFullRealm }}</b></span>
      <span class="self-item"><i>修为</i><b>{{ fmtNum(me.cultivation) }}</b></span>
      <span class="self-item"><i>灵石</i><b>{{ fmtNum(me.stonesBalance) }}</b></span>
      <span class="self-item"><i>贡献</i><b>{{ fmtNum(me.contributionBalance) }}</b></span>
      <span class="self-note">论道即修炼——开坛、听道、驳道皆有真实结算</span>
    </section>

    <!-- 规矩牌 -->
    <section class="rules">
      <div class="rule">
        <span class="rule-icon">🕯️</span>
        <b>开坛讲道</b>
        <p>设坛需 20 灵石。讲道梳理己身道法，修为 +60~150。每 60 秒可开一坛。</p>
      </div>
      <div class="rule">
        <span class="rule-icon">🔥</span>
        <b>香火供奉</b>
        <p>花 10 灵石上香听道：自己修为 +15~40，帖主得 5 贡献分成。一人一坛一炷香。</p>
      </div>
      <div class="rule">
        <span class="rule-icon">⚔️</span>
        <b>驳 道</b>
        <p>押 50 修为上台论剑：45% 压服对方吞其道韵 +120~300，败则道心受挫 -50。修为不足 50 者没资格上台。</p>
      </div>
    </section>

    <!-- 操作条 -->
    <section class="ops">
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
      <button class="compose-btn" type="button" @click="openCompose">开 坛 讲 道 <small>20灵石</small></button>
    </section>

    <!-- 发帖面板 -->
    <section v-if="composing" class="compose">
      <div class="compose-head">
        <h2>开 坛 讲 道</h2>
        <button class="detail-close" type="button" @click="composing = false">✕</button>
      </div>
      <input
        v-model.trim="form.title"
        class="compose-title"
        type="text"
        maxlength="100"
        placeholder="坛名（1-100 字）"
      >
      <textarea
        v-model.trim="form.content"
        class="compose-content"
        rows="5"
        maxlength="2000"
        placeholder="讲义正文（1-2000 字，魔道深浅、修士是非、奇闻异志，言之有物）"
      ></textarea>
      <div class="compose-foot">
        <span class="compose-note">落款：{{ username }} · 设坛香火 20 灵石 · 讲道得修为 60~150</span>
        <button class="compose-submit" type="button" :disabled="submitting" @click="submit">
          {{ submitting ? '开 坛 中……' : '开 坛' }}
        </button>
      </div>
    </section>

    <!-- 帖子列表 -->
    <section class="posts-wrap">
      <p v-if="error" class="empty">{{ error }}</p>
      <p v-else-if="!loading && !posts.length" class="empty">血辩台冷冷清清，且开第一坛</p>

      <ul v-else class="post-list">
        <li v-for="p in posts" :key="p.id" class="post-card" :class="{ own: isOwn(p) }">
          <div class="post-head">
            <span class="post-avatar">{{ p.author?.slice(0, 1) || '道' }}</span>
            <div class="post-who">
              <h3>{{ p.title }}</h3>
              <p class="post-meta">
                {{ p.author }}<template v-if="isOwn(p)">（你）</template>
                · {{ fmtTime(p.createTime) }} · {{ p.views }} 围观
                · 🔥 {{ p.likes }} · ⚔️ {{ p.counters || 0 }} 被驳
              </p>
            </div>
          </div>
          <p class="post-body">{{ p.content }}</p>
          <div class="post-actions">
            <button
              class="act-btn incense"
              type="button"
              :disabled="isOwn(p) || incensedIds.has(p.id)"
              @click="onIncense(p)"
            >{{ isOwn(p) ? '自家坛口' : incensedIds.has(p.id) ? '已供香火' : '🔥 供奉 · 10灵石' }}</button>
            <button
              class="act-btn counter"
              type="button"
              :disabled="isOwn(p) || counteredIds.has(p.id)"
              @click="onCounter(p)"
            >{{ isOwn(p) ? '不可自驳' : counteredIds.has(p.id) ? '已驳过' : '⚔️ 驳道 · 押50修为' }}</button>
          </div>
        </li>
      </ul>

      <div v-if="pages > 1" class="pager">
        <button type="button" class="pager-btn" :disabled="page <= 1" @click="gotoPage(page - 1)">上一页</button>
        <span class="pager-info">第 {{ page }} / {{ pages }} 页</span>
        <button type="button" class="pager-btn" :disabled="page >= pages" @click="gotoPage(page + 1)">下一页</button>
      </div>
    </section>

    <!-- 结算弹层 -->
    <div v-if="result" class="result-mask" @click.self="result = null">
      <div class="result-panel" :class="result.win === false ? 'fail' : ''">
        <button class="detail-close" type="button" @click="result = null">✕</button>
        <p class="result-title">{{ result.title }}</p>
        <p class="result-delta" :class="result.delta >= 0 ? 'gain' : 'loss'">
          {{ result.delta >= 0 ? `修为 +${result.delta}` : `修为 -${Math.abs(result.delta)}` }}
        </p>
        <p class="result-sub">
          灵石 -{{ result.costStones || 0 }}
          <template v-if="result.authorContribution"> · 帖主得贡献 {{ result.authorContribution }}</template>
        </p>
        <p class="result-story">{{ result.story }}</p>
        <p class="result-now">
          今修为 <b>{{ fmtNum(result.cultivation) }}</b> · 境界 <b>{{ resultFullRealm }}</b>
        </p>
        <p v-if="result.breakthrough" class="result-break">✦ 境界突破：{{ result.fromRealm }} → {{ result.toRealm }} ✦</p>
      </div>
    </div>

    <footer class="page-foot">© 2026 寂幽门 · 血辩台 · 道理讲不过，拳头总讲得过</footer>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import { counterPost, createPost, fetchPosts, incensePost } from '../api/forum'
import { fetchCultivationInfo } from '../api/cultivation'
import { fullRealm, stageOf } from '../utils/realm'

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const sort = ref('new')
const sortOptions = [
  { value: 'new', label: '最新' },
  { value: 'hot', label: '最热' }
]

const loading = ref(false)
const error = ref('')
const posts = ref([])
const page = ref(1)
const pageSize = 10
const pages = ref(0)

// 我的道行（修为/境界/灵石/贡献）
const me = ref({})

/** 完整境界（大境界 + 按修为折算的小层次） */
const meFullRealm = computed(() =>
  fullRealm(me.value.realm || '炼气', stageOf(me.value.realm || '炼气', me.value.cultivation || 0))
)
/** 修炼结果完整境界 */
const resultFullRealm = computed(() =>
  result.value
    ? fullRealm(result.value.realm || '炼气', stageOf(result.value.realm || '炼气', result.value.cultivation || 0))
    : ''
)

// 动作状态：本页内供奉过 / 驳过的帖子 id
const incensedIds = ref(new Set())
const counteredIds = ref(new Set())

// 开坛
const composing = ref(false)
const submitting = ref(false)
const form = ref({ title: '', content: '' })

// 结算弹层
const result = ref(null)

const isOwn = computed(() => p => props.username && p.author === props.username)

onMounted(() => {
  load()
  loadMe()
})

async function loadMe() {
  if (!props.username) return
  try {
    me.value = await fetchCultivationInfo(props.username)
  } catch {
    /* 道行条加载失败不阻塞主列表 */
  }
}

async function load(toPage = 1) {
  loading.value = true
  error.value = ''
  try {
    const data = await fetchPosts({
      sort: sort.value, page: toPage, size: pageSize, username: props.username
    })
    posts.value = data.list || []
    pages.value = data.pages || 0
    page.value = data.page || toPage
    incensedIds.value = new Set(data.incensedIds || [])
    counteredIds.value = new Set(data.counteredIds || [])
  } catch (e) {
    error.value = e.message || '血辩台加载失败'
  } finally {
    loading.value = false
  }
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

function openCompose() {
  composing.value = true
  form.value = { title: '', content: '' }
}

async function submit() {
  if (!form.value.title) {
    showToast('坛名不可为空')
    return
  }
  if (!form.value.content) {
    showToast('讲义正文不可为空')
    return
  }
  submitting.value = true
  try {
    const res = await createPost({
      author: props.username || '道友',
      title: form.value.title,
      content: form.value.content
    })
    composing.value = false
    showResult('开坛讲道 · 功成', res)
    await load(1)
    loadMe()
  } catch (e) {
    showToast(e.message || '开坛失败')
  } finally {
    submitting.value = false
  }
}

async function onIncense(post) {
  try {
    const res = await incensePost(post.id, props.username)
    post.likes = res.likes
    incensedIds.value.add(post.id)
    showResult('香火供奉 · 听道有得', res)
    loadMe()
  } catch (e) {
    showToast(e.message || '供奉失败')
  }
}

async function onCounter(post) {
  try {
    const res = await counterPost(post.id, props.username)
    post.counters = res.counters
    counteredIds.value.add(post.id)
    showResult(res.win ? '驳道 · 压服对方' : '驳道 · 落败', res)
    loadMe()
  } catch (e) {
    showToast(e.message || '驳道失败')
  }
}

function showResult(title, res) {
  result.value = { title, ...res }
}

function fmtNum(n) {
  return (n ?? 0).toLocaleString('zh-CN')
}

function fmtTime(s) {
  if (!s) return '不详'
  return String(s).replace('T', ' ').slice(0, 16)
}
</script>

<style scoped>
.page {
  position: relative;
  width: 100%;
  max-width: 1320px;
  margin: 0 auto;
  background: rgba(8, 5, 12, .20);
  border: 1px solid rgba(196, 154, 92, .18);
  border-radius: 22px;
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .06),
    0 24px 60px rgba(0, 0, 0, .50),
    0 0 50px rgba(200, 16, 46, .12);
}

/* ===== 堂名 ===== */
.hero {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 34px 32px 18px;
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

/* ===== 我的道行 ===== */
.self-bar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px 18px;
  margin: 0 32px 14px;
  padding: 10px 16px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(12, 8, 18, .6);
}

.self-item { display: flex; align-items: baseline; gap: 6px; }

.self-item i {
  font-style: normal;
  font-size: 12px;
  color: var(--text-dim);
  letter-spacing: 1px;
}

.self-item b {
  font-size: 14px;
  color: var(--gold-soft);
  font-variant-numeric: tabular-nums;
}

.self-note {
  margin-left: auto;
  font-size: 12px;
  color: var(--text-dim);
  letter-spacing: 1px;
}

/* ===== 规矩牌 ===== */
.rules {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  margin: 0 32px 16px;
}

.rule {
  padding: 12px 14px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(12, 8, 18, .55);
}

.rule-icon { font-size: 18px; margin-right: 6px; }

.rule b {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 14px;
  letter-spacing: 2px;
  color: var(--gold-soft);
}

.rule p {
  margin: 6px 0 0;
  font-size: 12px;
  line-height: 1.7;
  color: var(--text-dim);
}

/* ===== 操作条 ===== */
.ops {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 0 32px 16px;
}

.sort-bar { display: flex; gap: 6px; }

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

.compose-btn {
  padding: 8px 24px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 10px;
  cursor: pointer;
  background: linear-gradient(135deg, #8c0f1d 0%, #c8102e 55%, #e23a4e 100%);
  color: #f7e9c4;
  font-family: inherit;
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 3px;
  box-shadow: 0 4px 18px rgba(200, 16, 46, .4), inset 0 0 10px rgba(0, 0, 0, .3);
  transition: transform .15s, filter .2s;
  flex-shrink: 0;
}

.compose-btn small {
  font-size: 11px;
  font-weight: 400;
  letter-spacing: 1px;
  color: rgba(247, 233, 196, .8);
  margin-left: 4px;
}

.compose-btn:hover { transform: translateY(-1px); filter: brightness(1.12); }

/* ===== 发帖面板 ===== */
.compose {
  margin: 0 32px 18px;
  padding: 18px 20px;
  border: 1px solid var(--gold);
  border-radius: 14px;
  background: rgba(12, 8, 18, .85);
  box-shadow: 0 0 24px rgba(200, 16, 46, .2);
}

.compose-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.compose-head h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 17px;
  letter-spacing: 4px;
  color: var(--gold-soft);
  margin: 0;
}

.detail-close {
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

.compose-title {
  width: 100%;
  height: 40px;
  margin-bottom: 10px;
  padding: 0 12px;
  border: 1px solid var(--border-strong);
  border-radius: 10px;
  background: var(--card-input);
  color: var(--text);
  font-family: inherit;
  font-size: 14px;
  outline: none;
}

.compose-title:focus,
.compose-content:focus { border-color: var(--gold); }

.compose-content {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--border-strong);
  border-radius: 10px;
  background: var(--card-input);
  color: var(--text);
  font-family: inherit;
  font-size: 14px;
  line-height: 1.8;
  resize: vertical;
  outline: none;
}

.compose-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 10px;
}

.compose-note { font-size: 12px; color: var(--text-dim); letter-spacing: 1px; }

.compose-submit {
  padding: 8px 26px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 10px;
  cursor: pointer;
  background: linear-gradient(135deg, #8c0f1d 0%, #c8102e 60%);
  color: #f7e9c4;
  font-family: inherit;
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 3px;
}

.compose-submit:disabled { opacity: .7; cursor: wait; }

/* ===== 帖子列表 ===== */
.posts-wrap { padding: 0 32px 24px; }

.empty {
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
  padding: 22px 0;
}

.post-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.post-card {
  padding: 14px 16px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(12, 8, 18, .72);
  transition: border-color .18s, background .18s;
}

.post-card:hover { border-color: var(--gold); background: rgba(28, 18, 36, .65); }

.post-card.own { border-color: rgba(212, 175, 55, .4); }

.post-head {
  display: flex;
  align-items: center;
  gap: 12px;
}

.post-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 15px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 1px solid var(--gold);
  flex-shrink: 0;
}

.post-who { flex: 1; min-width: 0; }

.post-who h3 {
  font-size: 15px;
  color: #f3e8d6;
  letter-spacing: 1px;
  margin: 0 0 3px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.post-meta { font-size: 12px; color: var(--text-dim); letter-spacing: 1px; margin: 0; }

.post-body {
  margin: 12px 0 0;
  font-size: 13px;
  line-height: 1.9;
  color: var(--text-soft);
  white-space: pre-wrap;
  word-break: break-word;
}

/* ===== 动作按钮 ===== */
.post-actions {
  display: flex;
  gap: 10px;
  margin-top: 12px;
}

.act-btn {
  padding: 6px 14px;
  border-radius: 999px;
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s, box-shadow .18s;
}

.act-btn:disabled { cursor: not-allowed; opacity: .55; }

.act-btn.incense {
  border: 1px solid rgba(226, 58, 78, .55);
  background: rgba(60, 12, 20, .5);
  color: #f3c8b0;
}

.act-btn.incense:hover:not(:disabled) {
  color: #f7e9c4;
  border-color: #e23a4e;
  background: linear-gradient(135deg, rgba(140, 15, 29, .6), rgba(200, 16, 46, .4));
  box-shadow: 0 0 10px rgba(200, 16, 46, .35);
}

.act-btn.counter {
  border: 1px solid rgba(212, 175, 55, .45);
  background: rgba(40, 30, 12, .4);
  color: var(--gold-soft);
}

.act-btn.counter:hover:not(:disabled) {
  color: #f7e9c4;
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(120, 90, 20, .5), rgba(180, 130, 40, .35));
  box-shadow: 0 0 10px rgba(212, 175, 55, .3);
}

/* ===== 结算弹层 ===== */
.result-mask {
  position: fixed;
  inset: 0;
  z-index: 60;
  display: grid;
  place-items: center;
  background: rgba(0, 0, 0, .55);
  backdrop-filter: blur(3px);
}

.result-panel {
  position: relative;
  width: min(440px, calc(100vw - 40px));
  padding: 26px 24px 22px;
  border: 1px solid var(--gold);
  border-radius: 16px;
  background: linear-gradient(160deg, #1a0d14, #12080f 70%);
  box-shadow: 0 0 40px rgba(200, 16, 46, .35), 0 24px 60px rgba(0, 0, 0, .6);
  text-align: center;
  animation: pop .25s ease-out;
}

.result-panel.fail { border-color: rgba(120, 120, 140, .6); box-shadow: 0 0 40px rgba(60, 60, 80, .35), 0 24px 60px rgba(0, 0, 0, .6); }

@keyframes pop {
  from { transform: scale(.92); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

.result-panel .detail-close {
  position: absolute;
  top: 12px;
  right: 12px;
}

.result-title {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 18px;
  letter-spacing: 4px;
  color: var(--gold-soft);
  margin: 0 0 10px;
}

.result-delta {
  font-size: 26px;
  font-weight: 700;
  margin: 0 0 4px;
  font-variant-numeric: tabular-nums;
}

.result-delta.gain { color: #ffb347; text-shadow: 0 0 14px rgba(255, 179, 71, .4); }
.result-delta.loss { color: #9aa0b5; }

.result-sub {
  font-size: 12px;
  color: var(--text-dim);
  letter-spacing: 1px;
  margin: 0 0 12px;
}

.result-story {
  font-size: 13px;
  line-height: 1.9;
  color: var(--text-soft);
  text-align: left;
  margin: 0 0 12px;
  padding: 10px 12px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: rgba(8, 5, 12, .5);
}

.result-now {
  font-size: 13px;
  color: var(--text-soft);
  margin: 0;
}

.result-now b { color: var(--gold-soft); }

.result-break {
  margin: 10px 0 0;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 15px;
  letter-spacing: 2px;
  color: #ffd700;
  text-shadow: 0 0 16px rgba(255, 215, 0, .5);
  animation: glow 1.6s ease-in-out infinite alternate;
}

@keyframes glow {
  from { filter: brightness(1); }
  to { filter: brightness(1.35); }
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
  .self-bar { margin: 0 18px 12px; }
  .self-note { display: none; }
  .rules { grid-template-columns: 1fr; margin: 0 18px 14px; }
  .ops { flex-wrap: wrap; padding: 0 18px 14px; }
  .compose { margin: 0 18px 16px; }
  .posts-wrap { padding: 0 18px 20px; }
  .post-meta { display: none; }
}
</style>
