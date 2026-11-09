<template>
  <div class="page">
    <div class="page-bg" aria-hidden="true"></div>

    <SectNav active="rank" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 榜名 -->
    <header class="hero">
      <span class="hero-seal">榜</span>
      <div>
        <h1>宗门榜</h1>
        <p class="hero-desc">以战力论高下，以贡献定尊卑</p>
      </div>
    </header>

    <!-- 堂口筛选 -->
    <section class="tabs-wrap">
      <div class="tabs">
        <button
          type="button"
          class="tab"
          :class="{ active: activeHall === '' }"
          @click="activeHall = ''"
        >🏯 全宗 <small class="tab-count">{{ members.length }}</small></button>
        <button
          v-for="(cnt, hall) in hallStats"
          :key="hall"
          type="button"
          class="tab"
          :class="{ active: activeHall === hall }"
          @click="activeHall = hall"
        >{{ hall }} <small class="tab-count">{{ cnt }}</small></button>
      </div>

      <p v-if="error" class="empty">{{ error }}</p>
      <p v-else-if="!filteredList.length" class="empty">此堂尚无人上榜</p>

      <ul v-else class="rank-list">
        <li
          v-for="(m, idx) in filteredList"
          :key="m.id"
          class="rank-row"
          :class="{ 'top-1': idx === 0 && activeHall === '', 'top-2': idx === 1 && activeHall === '', 'top-3': idx === 2 && activeHall === '' }"
        >
          <span class="rank-no" :class="{ medal: idx < 3 && activeHall === '' }">{{ idx + 1 }}</span>
          <span class="rank-avatar">{{ m.icon || '🧑‍🦲' }}</span>
          <div class="rank-main">
            <h3>
              {{ m.name }}
              <small v-if="m.title" class="rank-title">{{ m.title }}</small>
            </h3>
            <p>{{ m.hall }} · 入宗 {{ fmtDate(m.createTime) }}</p>
          </div>
          <span class="realm-pill" :class="realmClass(m.realm)">{{ m.realm }}</span>
          <div class="rank-nums">
            <span class="power">战力 {{ fmtNum(m.power) }}</span>
            <span class="contrib">贡献 {{ fmtNum(m.contribution) }}</span>
          </div>
        </li>
      </ul>
    </section>

    <footer class="page-foot">© 2026 逆天魔宗 · 宗门榜 · 榜上有名者，皆踏骨而行</footer>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import { fetchHallStats, fetchRank } from '../api/sect'

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const members = ref([])
const hallStats = ref({})
const activeHall = ref('')
const error = ref('')

const filteredList = computed(() =>
  activeHall.value ? members.value.filter(m => m.hall === activeHall.value) : members.value
)

onMounted(async () => {
  try {
    const [list, halls] = await Promise.all([fetchRank(), fetchHallStats()])
    members.value = list || []
    hallStats.value = halls || {}
  } catch (e) {
    error.value = e.message || '宗门榜加载失败'
    showToast(error.value)
  }
})

/** 战力/贡献：万为单位缩写 */
function fmtNum(n) {
  const v = Number(n || 0)
  if (v >= 10000) {
    const w = v / 10000
    return (w >= 100 ? Math.round(w) : w.toFixed(1)) + '万'
  }
  return v.toLocaleString('zh-CN')
}

function fmtDate(s) {
  if (!s) return '不详'
  return String(s).slice(0, 10)
}

/** 境界配色：越高越红 */
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

/* ===== 榜名 ===== */
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

/* ===== 堂口筛选 ===== */
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

/* ===== 榜单 ===== */
.empty {
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
  padding: 22px 0;
}

.rank-list {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
}

.rank-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: rgba(12, 8, 18, .66);
  transition: background .15s;
}

.rank-row + .rank-row { border-top: 1px solid var(--border); }
.rank-row:hover { background: rgba(28, 18, 36, .65); }

.rank-row.top-1 { background: linear-gradient(90deg, rgba(200, 16, 46, .25), rgba(12, 8, 18, .7)); }
.rank-row.top-2 { background: linear-gradient(90deg, rgba(200, 16, 46, .16), rgba(12, 8, 18, .7)); }
.rank-row.top-3 { background: linear-gradient(90deg, rgba(200, 16, 46, .10), rgba(12, 8, 18, .7)); }

.rank-no {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  display: grid;
  place-items: center;
  font-size: 14px;
  font-weight: 700;
  color: var(--text-soft);
  background: rgba(212, 175, 55, .10);
  border: 1px solid var(--border-strong);
  flex-shrink: 0;
}

.rank-no.medal {
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border-color: var(--gold);
  box-shadow: 0 0 12px rgba(200, 16, 46, .45);
}

.rank-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 20px;
  background: rgba(0, 0, 0, .35);
  border: 1px solid var(--border-strong);
  flex-shrink: 0;
}

.rank-main { flex: 1; min-width: 0; }

.rank-main h3 {
  font-size: 15px;
  color: #f3e8d6;
  letter-spacing: 1px;
  margin: 0 0 3px;
}

.rank-title {
  margin-left: 8px;
  font-size: 11px;
  font-weight: 400;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .8);
}

.rank-main p {
  font-size: 12px;
  color: var(--text-dim);
  letter-spacing: 1px;
  margin: 0;
}

.realm-pill {
  padding: 3px 12px;
  font-size: 12px;
  letter-spacing: 2px;
  border-radius: 999px;
  border: 1px solid var(--border-strong);
  color: var(--text-soft);
  background: rgba(12, 8, 18, .6);
  flex-shrink: 0;
}

.r-mozun { color: #ffd76a; border-color: var(--gold); background: linear-gradient(135deg, rgba(140, 15, 29, .8), rgba(200, 16, 46, .6)); box-shadow: 0 0 12px rgba(200, 16, 46, .4); }
.r-dujie { color: #e23a4e; border-color: rgba(226, 58, 78, .6); }
.r-dacheng { color: #ff8a5c; border-color: rgba(255, 138, 92, .5); }
.r-heti { color: #d4af37; border-color: rgba(212, 175, 55, .5); }
.r-lianxu { color: #9fd0ff; border-color: rgba(159, 208, 255, .4); }
.r-huashen { color: #b48aff; border-color: rgba(180, 138, 255, .4); }
.r-low { color: var(--text-soft); }

.rank-nums {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  flex-shrink: 0;
}

.power { font-size: 13px; letter-spacing: 1px; color: rgba(226, 58, 78, .9); }
.contrib { font-size: 11px; letter-spacing: 1px; color: rgba(212, 175, 55, .6); }

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
  .rank-main p { display: none; }
  .contrib { display: none; }
  .realm-pill { display: none; }
}
</style>
