<template>
  <div class="page">
    <SectNav active="profile" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 洞府之名 -->
    <header class="hero">
      <span class="hero-seal">吾</span>
      <div>
        <h1>洞府</h1>
        <p class="hero-desc">一洞一府一乾坤，道友的修行印记皆在此处</p>
      </div>
    </header>

    <p v-if="error" class="empty">{{ error }}</p>

    <template v-else>
      <!-- ===== 道友档案卡 ===== -->
      <section class="profile-card">
        <div class="avatar-big" :class="{ editing: editing }" @click="editing = !editing" title="点击修改档案">
          {{ profile.icon || '🧙' }}
        </div>

        <div class="profile-main">
          <div class="name-line">
            <h2>{{ profile.nickname || username }}</h2>
            <span class="realm-pill" :class="realmClass(profile.realm)">{{ profile.realm || '炼气' }}</span>
            <span class="hall-tag">{{ profile.hall || '血煞堂' }}</span>
          </div>
          <p class="uname-line">道号 {{ username }} · 入宗 {{ fmtDate(user.createdAt) }}</p>
          <p class="bio">「{{ profile.bio || '此人懒于参道，尚未留下道语。' }}」</p>
        </div>

        <button class="edit-btn" type="button" @click="editing = !editing">
          {{ editing ? '收起' : '修改档案' }}
        </button>
      </section>

      <!-- ===== 修改档案表单 ===== -->
      <section v-if="editing" class="edit-panel">
        <div class="form-grid">
          <label class="field">
            <span>道号</span>
            <input v-model="form.nickname" maxlength="20" placeholder="展示用的道号" />
          </label>
          <label class="field">
            <span>头像 emoji</span>
            <input v-model="form.icon" maxlength="4" placeholder="🧙" />
          </label>
          <label class="field">
            <span>境界</span>
            <select v-model="form.realm">
              <option v-for="r in REALMS" :key="r" :value="r">{{ r }}</option>
            </select>
          </label>
          <label class="field">
            <span>堂口</span>
            <select v-model="form.hall">
              <option v-for="h in HALLS" :key="h" :value="h">{{ h }}</option>
            </select>
          </label>
          <label class="field field-wide">
            <span>道语（签名）</span>
            <input v-model="form.bio" maxlength="100" placeholder="留一句道语镇宅" />
          </label>
        </div>
        <div class="form-actions">
          <button class="btn-ghost" type="button" @click="cancelEdit">还 原</button>
          <button class="btn-primary" type="button" :disabled="saving" @click="submit">
            {{ saving ? '封存中…' : '封存档案' }}
          </button>
        </div>
      </section>

      <!-- ===== 修行统计（跨模块联动） ===== -->
      <section class="stats-row">
        <div class="stat">
          <b>{{ stats.postCount }}</b>
          <span>论道之帖</span>
          <small @click="go('forum')" class="stat-link">去论道 →</small>
        </div>
        <div class="stat">
          <b>{{ stats.likeCount }}</b>
          <span>道心相印</span>
          <small class="stat-link" @click="loadTab('posts')">看我的帖 →</small>
        </div>
        <div class="stat">
          <b>{{ stats.searchCount }}</b>
          <span>求索次数</span>
          <small @click="go('home')" class="stat-link">去求索 →</small>
        </div>
        <div class="stat">
          <b>{{ daysInSect }}</b>
          <span>入宗天数</span>
          <small class="stat-dim">自 {{ fmtDate(user.createdAt) }}</small>
        </div>
      </section>

      <!-- ===== 联动记录 ===== -->
      <section class="tabs-wrap">
        <div class="tabs">
          <button type="button" class="tab" :class="{ active: tab === 'posts' }" @click="loadTab('posts')">
            📜 我的论道帖 <small class="tab-count">{{ myPosts.length }}</small>
          </button>
          <button type="button" class="tab" :class="{ active: tab === 'searches' }" @click="loadTab('searches')">
            🔍 求索足迹 <small class="tab-count">{{ mySearches.length }}</small>
          </button>
        </div>

        <!-- 我的帖子 -->
        <template v-if="tab === 'posts'">
          <p v-if="!myPosts.length" class="empty">
            尚无论道之帖 —— <span class="link" @click="go('forum')">前往论道</span> 留下第一篇吧
          </p>
          <ul v-else class="post-list">
            <li v-for="p in myPosts" :key="p.id" class="post-row">
              <span class="post-avatar">{{ (profile.nickname || username).slice(0, 1) }}</span>
              <div class="post-main">
                <h3>{{ p.title }}</h3>
                <p class="post-meta">{{ fmtTime(p.createTime) }}</p>
              </div>
              <div class="post-nums">
                <span class="like">♡ {{ p.likes || 0 }}</span>
                <span class="view">{{ p.views || 0 }} 围观</span>
              </div>
            </li>
          </ul>
        </template>

        <!-- 搜索足迹 -->
        <template v-else>
          <p v-if="!mySearches.length" class="empty">
            尚无求索记录 —— <span class="link" @click="go('home')">回到首页</span> 搜一搜功法秘闻
          </p>
          <ul v-else class="search-list">
            <li v-for="s in mySearches" :key="s.id" class="search-row">
              <span class="kw">{{ s.keyword }}</span>
              <span class="hit">{{ s.resultCount ?? 0 }} 条机缘</span>
              <span class="time">{{ fmtTime(s.createTime) }}</span>
              <span class="again link" @click="searchAgain(s.keyword)">再寻一次</span>
            </li>
          </ul>
        </template>
      </section>
    </template>

    <footer class="page-foot">© 2026 逆天魔宗 · 洞府 · 修行的每一步，皆有印记</footer>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import { fetchMyPosts, fetchMySearches, fetchProfile, saveProfile } from '../api/profile'

const props = defineProps({
  username: { type: String, default: '' }
})

const emit = defineEmits(['nav', 'logout', 'search'])

const { showToast } = useToast()

const REALMS = ['炼气', '筑基', '金丹', '元婴', '化神', '炼虚', '合体', '大乘', '渡劫', '魔尊']
const HALLS = ['主殿', '血煞堂', '幽冥堂', '千机堂', '执法堂', '炼丹堂']

const error = ref('')
const profile = ref({})
const user = ref({})
const stats = ref({ postCount: 0, likeCount: 0, searchCount: 0 })

const editing = ref(false)
const saving = ref(false)
const form = ref({ nickname: '', icon: '', realm: '炼气', hall: '血煞堂', bio: '' })

const tab = ref('posts')
const myPosts = ref([])
const mySearches = ref([])

/** 入宗天数 */
const daysInSect = computed(() => {
  if (!user.value.createdAt) return '—'
  const days = Math.floor((Date.now() - new Date(user.value.createdAt).getTime()) / 86400000)
  return days < 1 ? '今' : String(days)
})

onMounted(load)

async function load() {
  try {
    const data = await fetchProfile(props.username)
    profile.value = data.profile || {}
    user.value = data.user || {}
    stats.value = data.stats || stats.value
    resetForm()
    loadTab('posts')
    prefetchLists()
  } catch (e) {
    error.value = e.message || '洞府加载失败'
    showToast(error.value)
  }
}

/** 两个联动列表一次性预取，保证 tab 上的计数准确 */
async function loadTab(key) {
  tab.value = key
}

async function prefetchLists() {
  try {
    const [posts, searches] = await Promise.all([
      fetchMyPosts(props.username),
      fetchMySearches(props.username)
    ])
    myPosts.value = posts || []
    mySearches.value = searches || []
  } catch (e) {
    showToast(e.message || '记录加载失败')
  }
}

function resetForm() {
  form.value = {
    nickname: profile.value.nickname || props.username,
    icon: profile.value.icon || '🧙',
    realm: profile.value.realm || '炼气',
    hall: profile.value.hall || '血煞堂',
    bio: profile.value.bio || ''
  }
}

function cancelEdit() {
  resetForm()
  editing.value = false
}

async function submit() {
  if (saving.value) return
  saving.value = true
  try {
    const saved = await saveProfile({ username: props.username, ...form.value })
    profile.value = saved || profile.value
    editing.value = false
    showToast('档案已封存')
  } catch (e) {
    showToast(e.message || '封存失败')
  } finally {
    saving.value = false
  }
}

/** 搜索足迹「再寻一次」：联动跳回首页并自动搜索 */
function searchAgain(keyword) {
  emit('search', keyword)
}

function go(key) {
  emit('nav', key)
}

function fmtDate(s) {
  return s ? String(s).slice(0, 10) : '不详'
}

function fmtTime(s) {
  return s ? String(s).slice(0, 16).replace('T', ' ') : ''
}

/** 境界配色：与宗门榜保持一致 */
function realmClass(realm) {
  switch (realm) {
    case '魔尊': return 'r-mozun'
    case '渡劫': return 'r-dujie'
    case '大乘': return 'r-dacheng'
    case '合体': return 'r-heti'
    case '炼虚': return 'r-lianxu'
    case '化神': return 'r-huashen'
    default: return 'r-low'
  }
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

/* ===== 榜名同款头部 ===== */
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
  color: rgba(226, 196, 110, .92);
  text-shadow: 0 1px 8px rgba(0, 0, 0, .75);
  margin: 6px 0 0;
}

/* ===== 档案卡 ===== */
.profile-card {
  display: flex;
  align-items: center;
  gap: 20px;
  margin: 0 32px 18px;
  padding: 20px 24px;
  background: rgba(10, 7, 15, .78);
  border: 1px solid var(--border);
  border-radius: 16px;
}

.avatar-big {
  width: 76px;
  height: 76px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 38px;
  line-height: 1;
  overflow: hidden;
  background: rgba(0, 0, 0, .45);
  border: 2px solid var(--gold);
  box-shadow: 0 0 22px rgba(200, 16, 46, .35);
  cursor: pointer;
  flex-shrink: 0;
  transition: box-shadow .18s, transform .18s;
}

.avatar-big:hover { box-shadow: 0 0 30px rgba(200, 16, 46, .55); }
.avatar-big.editing { transform: scale(1.05); box-shadow: 0 0 30px rgba(212, 175, 55, .5); }

.profile-main { flex: 1; min-width: 0; }

.name-line {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.name-line h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 22px;
  letter-spacing: 2px;
  color: #f3e8d6;
  margin: 0;
  text-shadow: 0 2px 12px rgba(200, 16, 46, .35);
}

.realm-pill {
  padding: 3px 12px;
  font-size: 12px;
  letter-spacing: 2px;
  border-radius: 999px;
  border: 1px solid var(--border-strong);
  color: var(--text-soft);
  background: rgba(12, 8, 18, .6);
}

.r-mozun { color: #ffd76a; border-color: var(--gold); background: linear-gradient(135deg, rgba(140, 15, 29, .8), rgba(200, 16, 46, .6)); box-shadow: 0 0 12px rgba(200, 16, 46, .4); }
.r-dujie { color: #e23a4e; border-color: rgba(226, 58, 78, .6); }
.r-dacheng { color: #ff8a5c; border-color: rgba(255, 138, 92, .5); }
.r-heti { color: #d4af37; border-color: rgba(212, 175, 55, .5); }
.r-lianxu { color: #9fd0ff; border-color: rgba(159, 208, 255, .4); }
.r-huashen { color: #b48aff; border-color: rgba(180, 138, 255, .4); }
.r-low { color: var(--text-soft); }

.hall-tag {
  font-size: 11px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .8);
  border: 1px dashed rgba(212, 175, 55, .4);
  border-radius: 8px;
  padding: 2px 8px;
}

.uname-line {
  font-size: 12px;
  color: rgba(200, 188, 172, .8);
  letter-spacing: 1px;
  margin: 6px 0 0;
}

.bio {
  font-size: 13px;
  color: rgba(240, 230, 216, .92);
  letter-spacing: 1px;
  margin: 8px 0 0;
}

.edit-btn {
  padding: 8px 16px;
  border: 1px solid var(--border-strong);
  border-radius: 9px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  flex-shrink: 0;
  transition: color .18s, border-color .18s;
}

.edit-btn:hover { color: var(--gold-soft); border-color: var(--gold); }

/* ===== 修改表单 ===== */
.edit-panel {
  margin: 0 32px 18px;
  padding: 18px 20px;
  background: rgba(12, 8, 18, .82);
  border: 1px solid rgba(196, 154, 92, .28);
  border-radius: 14px;
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
.field select {
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
}

.field input:focus,
.field select:focus { border-color: var(--gold); }

.field-wide { grid-column: 1 / -1; }

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 14px;
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

/* ===== 修行统计 ===== */
.stats-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  margin: 0 32px 22px;
}

.stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 16px 10px 12px;
  background: rgba(10, 7, 15, .78);
  border: 1px solid var(--border);
  border-radius: 14px;
}

.stat b {
  font-size: 26px;
  font-family: "STKaiti", "KaiTi", serif;
  color: #f3e8d6;
  text-shadow: 0 0 16px rgba(200, 16, 46, .45);
}

.stat span {
  font-size: 12px;
  letter-spacing: 2px;
  color: var(--text-soft);
}

.stat-link {
  font-size: 11px;
  color: rgba(212, 175, 55, .7);
  cursor: pointer;
  margin-top: 3px;
}

.stat-link:hover { color: var(--gold-soft); }

.stat-dim {
  font-size: 11px;
  color: var(--text-dim);
  margin-top: 3px;
}

/* ===== 联动记录 ===== */
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

.tab-count { font-size: 11px; color: var(--text-dim); letter-spacing: 0; }

.empty {
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
  padding: 22px 0;
}

.link { color: var(--gold-soft); cursor: pointer; }
.link:hover { text-decoration: underline; }

/* 我的帖子列表（对齐论道风格） */
.post-list,
.search-list {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
}

.post-row,
.search-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: rgba(10, 7, 15, .78);
  transition: background .15s;
}

.post-row + .post-row,
.search-row + .search-row { border-top: 1px solid var(--border); }
.post-row:hover,
.search-row:hover { background: rgba(28, 18, 36, .65); }

.post-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 16px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 1px solid var(--gold);
  flex-shrink: 0;
}

.post-main { flex: 1; min-width: 0; }

.post-main h3 {
  font-size: 14px;
  color: #f3e8d6;
  letter-spacing: 1px;
  margin: 0 0 3px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.post-meta {
  font-size: 12px;
  color: var(--text-dim);
  letter-spacing: 1px;
  margin: 0;
}

.post-nums {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  flex-shrink: 0;
}

.like { font-size: 13px; color: rgba(226, 58, 78, .9); }
.view { font-size: 11px; color: var(--text-dim); }

/* 搜索足迹列表 */
.kw {
  flex: 1;
  min-width: 0;
  font-size: 14px;
  letter-spacing: 1px;
  color: #f3e8d6;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.hit {
  font-size: 12px;
  color: rgba(212, 175, 55, .75);
  flex-shrink: 0;
}

.time {
  font-size: 12px;
  color: var(--text-dim);
  flex-shrink: 0;
}

.again {
  font-size: 12px;
  flex-shrink: 0;
}

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
  .profile-card { margin: 0 18px 14px; flex-wrap: wrap; }
  .stats-row { grid-template-columns: repeat(2, 1fr); margin: 0 18px 18px; }
  .tabs-wrap { padding: 0 18px 20px; }
  .form-grid { grid-template-columns: 1fr; }
  .time { display: none; }
  .view { display: none; }
}
</style>
