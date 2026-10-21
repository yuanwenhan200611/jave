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

    <!-- 主视觉 + 搜索栏 -->
    <header class="hero">
      <div class="hero-seal">宗</div>
      <h1>恭迎 {{ username }} 道友归宗</h1>
      <p class="hero-sub">执掌乾坤，搜罗诸天万界之秘</p>

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
            placeholder="检索功法、秘境、同道、法宝……"
            @input="searched = false"
          >
          <button class="search-btn" type="submit">搜 索</button>
        </div>
        <p v-if="searched" class="search-hint">检索「{{ lastQuery }}」—— 后端检索接口尚未接入</p>
      </form>
    </header>

    <!-- 快速入口（占位内容，其余页面待建设） -->
    <section class="entries">
      <div
        v-for="entry in entries"
        :key="entry.title"
        class="entry-card"
        @click="onEntry(entry)"
      >
        <div class="entry-icon">{{ entry.icon }}</div>
        <h3>{{ entry.title }}</h3>
        <p>{{ entry.desc }}</p>
      </div>
    </section>

    <footer class="home-foot">© 2026 逆天魔宗 · 堕魔者，永生不灭</footer>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { useToast } from '../composables/useToast'

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

const navItems = [
  { key: 'home', label: '首页' },
  { key: 'secret', label: '秘境' },
  { key: 'skill', label: '功法阁' },
  { key: 'rank', label: '宗门榜' },
  { key: 'forum', label: '论道' }
]

const entries = [
  { icon: '📜', title: '功法总览', desc: '诸天功法，皆可习练' },
  { icon: '🗺️', title: '秘境探幽', desc: '无尽秘境，待你开辟' },
  { icon: '⚗️', title: '丹药炼制', desc: '逆天改命之丹' },
  { icon: '🗡️', title: '法宝祭炼', desc: '神兵利器，掌中乾坤' },
  { icon: '🐉', title: '灵兽收服', desc: '万兽臣服，皆入麾下' },
  { icon: '📖', title: '宗门典籍', desc: '万载传承，尽数收录' }
]

const avatarChar = computed(() => (props.username ? props.username.slice(0, 1).toUpperCase() : '道'))

function onSearch() {
  if (!query.value) {
    showToast('请输入检索词条')
    return
  }
  lastQuery.value = query.value
  searched.value = true
  // 后端检索接口尚未接入，仅作前端占位提示
  showToast(`检索「${query.value}」—— 后端检索接口尚未接入`)
}

function onNav(item) {
  if (item.key === 'home') {
    activeNav.value = 'home'
    return
  }
  showToast(`「${item.label}」页面尚未开辟`)
}

function onEntry(entry) {
  showToast(`「${entry.title}」页面待建设`)
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
  padding: 16px 28px;
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
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: rgba(0, 0, 0, .35);
  border: 1px solid rgba(212, 175, 55, .55);
  display: grid;
  place-items: center;
  box-shadow: 0 0 16px rgba(212, 175, 55, .25);
}

.nav-mark svg { width: 20px; height: 20px; }

.nav-title { font-size: 17px; }

.nav-links {
  display: flex;
  align-items: center;
  gap: 6px;
  list-style: none;
  margin: 0;
  padding: 0;
  flex: 1;
}

.nav-links li {
  padding: 8px 16px;
  border-radius: 9px;
  font-size: 14px;
  letter-spacing: 2px;
  color: var(--text-soft);
  cursor: pointer;
  transition: color .18s, background .18s, box-shadow .18s;
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
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 15px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 1px solid var(--gold);
  box-shadow: 0 0 12px rgba(200, 16, 46, .5);
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
  padding: 7px 14px;
  border: 1px solid var(--border-strong);
  border-radius: 9px;
  background: rgba(12, 8, 18, .6);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s;
}

.logout:hover {
  color: var(--gold-soft);
  border-color: var(--gold);
  background: rgba(212, 175, 55, .10);
}

/* ===== 主视觉 + 搜索栏 ===== */
.hero {
  position: relative;
  text-align: center;
  padding: 56px 32px 48px;
  background:
    radial-gradient(120% 90% at 50% -20%, rgba(200, 16, 46, .28), transparent 60%),
    radial-gradient(80% 60% at 80% 120%, rgba(123, 15, 29, .30), transparent 60%);
  overflow: hidden;
}

.hero-seal {
  width: 66px;
  height: 66px;
  margin: 0 auto 22px;
  border-radius: 16px;
  display: grid;
  place-items: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 40px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 2px solid var(--gold);
  box-shadow: 0 6px 22px rgba(200, 16, 46, .5), inset 0 0 12px rgba(0, 0, 0, .35);
  transform: rotate(-6deg);
}

.hero h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 30px;
  line-height: 1.4;
  font-weight: 700;
  letter-spacing: 4px;
  color: #f3e8d6;
  text-shadow: 0 2px 18px rgba(200, 16, 46, .45);
}

.hero-sub {
  margin-top: 12px;
  font-size: 14px;
  letter-spacing: 2px;
  color: rgba(236, 230, 245, .72);
}

.search {
  margin: 34px auto 0;
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
  height: 44px;
  border: 0;
  background: transparent;
  outline: none;
  font-family: inherit;
  font-size: 15px;
  color: var(--text);
}

.search-input::placeholder { color: var(--text-dim); }

.search-btn {
  height: 44px;
  padding: 0 26px;
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
}

.search-btn:hover { transform: translateY(-1px); filter: brightness(1.12); }
.search-btn:active { transform: translateY(0); }

.search-hint {
  margin-top: 12px;
  font-size: 13px;
  letter-spacing: 1px;
  color: var(--text-soft);
}

/* ===== 快速入口 ===== */
.entries {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  padding: 8px 32px 40px;
}

.entry-card {
  padding: 22px 20px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: rgba(12, 8, 18, .55);
  cursor: pointer;
  transition: transform .15s, border-color .18s, box-shadow .2s, background .18s;
}

.entry-card:hover {
  transform: translateY(-3px);
  border-color: var(--gold);
  background: rgba(28, 18, 36, .7);
  box-shadow: 0 10px 28px rgba(200, 16, 46, .22), 0 0 18px rgba(212, 175, 55, .14);
}

.entry-icon {
  font-size: 30px;
  line-height: 1;
  margin-bottom: 14px;
  filter: drop-shadow(0 0 8px rgba(200, 16, 46, .4));
}

.entry-card h3 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 19px;
  font-weight: 700;
  letter-spacing: 2px;
  color: var(--gold-soft);
  margin-bottom: 8px;
}

.entry-card p {
  font-size: 13px;
  line-height: 1.7;
  color: var(--text-soft);
  letter-spacing: 1px;
}

.home-foot {
  padding: 18px 32px 22px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .5);
  border-top: 1px solid var(--border);
}

/* ===== 响应式 ===== */
@media (max-width: 780px) {
  .navbar {
    flex-wrap: wrap;
    gap: 12px;
    padding: 14px 18px;
  }
  .nav-links {
    order: 3;
    width: 100%;
    overflow-x: auto;
    flex-wrap: nowrap;
  }
  .nav-user { margin-left: auto; }
  .entries { grid-template-columns: repeat(2, 1fr); padding: 8px 18px 32px; }
  .hero { padding: 40px 18px 36px; }
  .hero h1 { font-size: 24px; letter-spacing: 2px; }
}

@media (max-width: 480px) {
  .entries { grid-template-columns: 1fr; }
  .uname { display: none; }
}
</style>
