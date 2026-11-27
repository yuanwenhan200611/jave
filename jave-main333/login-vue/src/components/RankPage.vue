<template>
  <div class="page">
    <SectNav active="rank" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 榜名 -->
    <header class="hero">
      <span class="hero-seal">榜</span>
      <div>
        <h1>宗门榜</h1>
        <p class="hero-desc">{{ tierDesc }}</p>
      </div>
    </header>

    <!-- 加载态 -->
    <div v-if="loading" class="state-panel">
      <span class="state-seal">榜</span>
      <p>正在开榜……</p>
    </div>

    <p v-else-if="error" class="empty error">{{ error }}</p>

    <template v-else>
      <!-- ===== 我的名次（当前榜内） ===== -->
      <section v-if="myEntry" class="my-rank">
        <div class="my-seal">
          <small>{{ tierName }}名次</small>
          <b>#{{ myRank }}</b>
          <span>本榜 {{ members.length }} 人</span>
        </div>
        <div class="my-info">
          <div class="my-name">
            <span class="rank-avatar">{{ myEntry.icon || '🧙' }}</span>
            <h2>{{ myEntry.name }}</h2>
            <span class="realm-pill" :class="realmClass(myEntry.realm)">{{ myEntry.realmFull || myEntry.realm }}</span>
            <span v-if="myEntry.title" class="rank-title">{{ myEntry.title }}</span>
            <span class="me-tag">本座</span>
          </div>
          <p class="my-meta">{{ myEntry.hall }} · 入宗 {{ fmtDate(myEntry.createTime) }} · 修为 {{ fmtNum(myEntry.cultivation) }}</p>
          <p class="my-hint">{{ gapText }}</p>
        </div>
        <div class="my-nums">
          <span :class="{ strong: sortBy === 'power' && tier !== 'disciple' }">战力 {{ fmtNum(myEntry.power) }}</span>
          <span :class="{ strong: sortBy === 'contribution' && tier !== 'disciple' }">贡献 {{ fmtNum(myEntry.contribution) }}</span>
        </div>
      </section>

      <!-- 玩家不在当前榜：给个明确去处 -->
      <section v-else-if="myAllEntry" class="my-rank off-board">
        <div class="my-seal">
          <small>你在本榜</small>
          <b>—</b>
          <span>境界未满</span>
        </div>
        <div class="my-info">
          <div class="my-name">
            <span class="rank-avatar">{{ myAllEntry.icon || '🧙' }}</span>
            <h2>{{ myAllEntry.name }}</h2>
            <span class="realm-pill" :class="realmClass(myAllEntry.realm)">{{ myAllEntry.realmFull || myAllEntry.realm }}</span>
            <span v-if="myAllEntry.title" class="rank-title">{{ myAllEntry.title }}</span>
            <span class="me-tag">本座</span>
          </div>
          <p class="my-meta">{{ myAllEntry.hall }} · 修为 {{ fmtNum(myAllEntry.cultivation) }} · 身份{{ myAllEntry.title || '本座' }}</p>
          <p class="my-hint">
            你在{{ tierOf(myAllEntry.realm) === 'elder' || tierOf(myAllEntry.realm) === 'supreme' ? '长老榜' : '弟子榜' }}第 {{ myAllRank }} 名，
            {{ tier === 'elder' ? `突破至 ${ELDER_MIN_REALM} 方可入长老榜` : '精进境界即可角逐长老榜' }}
          </p>
        </div>
        <button type="button" class="jump-btn" @click="switchTier(tier === 'elder' ? 'disciple' : 'elder')">
          去{{ tier === 'elder' ? '弟子榜' : '长老榜' }} →
        </button>
      </section>

      <!-- ===== 榜别切换 ===== -->
      <section class="toolbar">
        <div class="tier-switch">
          <button type="button" :class="{ active: tier === 'elder' }" @click="switchTier('elder')">
            👑 长老榜 <small>{{ elderCount }}</small>
          </button>
          <button type="button" :class="{ active: tier === 'disciple' }" @click="switchTier('disciple')">
            🗡️ 弟子榜 <small>{{ discipleCount }}</small>
          </button>
        </div>

        <div class="board-switch">
          <span v-if="tier === 'disciple'" class="board-fixed">📿 修为榜 · 按境界排位</span>
          <template v-else>
            <button type="button" :class="{ active: sortBy === 'power' }" @click="switchSort('power')">⚔️ 战力榜</button>
            <button type="button" :class="{ active: sortBy === 'contribution' }" @click="switchSort('contribution')">💰 贡献榜</button>
          </template>
        </div>

        <div class="tools">
          <input v-model="keyword" type="search" maxlength="20" placeholder="寻道号 / 境界 / 堂口" class="search-input" />
          <button type="button" class="refresh-btn" :disabled="refreshing" @click="load(false)" title="重新开榜">
            {{ refreshing ? '…' : '⟳' }}
          </button>
        </div>
      </section>

      <!-- ===== 修为小层次图例 ===== -->
      <section class="stage-legend">
        <span v-for="r in legendRealms" :key="r" class="stage-legend-item">
          <b :class="realmClass(r)">{{ r }}</b><small>{{ STAGES[r].join(' · ') }}</small>
        </span>
      </section>

      <!-- ===== 前三领奖台 ===== -->
      <section v-if="podiumSlots.length === 3" class="podium">
        <div
          v-for="slot in podiumSlots"
          :key="slot.rank"
          class="podium-slot"
          :class="'p-' + slot.rank"
        >
          <span class="podium-crown">{{ slot.rank === 1 ? '👑' : slot.rank === 2 ? '🥈' : '🥉' }}</span>
          <span class="podium-avatar">{{ slot.m.icon || '🧑‍🦲' }}</span>
          <h3>{{ slot.m.name }}<em v-if="slot.m.me">本座</em></h3>
          <span class="podium-realm" :class="realmClass(slot.m.realm)">{{ slot.m.realmFull || slot.m.realm }} · {{ slot.m.title }}</span>
          <b class="podium-value">{{ boardValue(slot.m) }}</b>
          <small class="podium-label">{{ boardLabel }}</small>
        </div>
      </section>

      <!-- 身份筛选 -->
      <section class="grade-wrap">
        <div class="grade-tabs">
          <button
            v-for="g in gradeStats"
            :key="g.key"
            type="button"
            class="grade-tab"
            :class="{ active: activeGrade === g.key }"
            @click="activeGrade = g.key"
          >{{ g.icon }} {{ g.key }} <small>{{ g.count }}</small></button>
        </div>
      </section>

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

        <p v-if="!filteredList.length" class="empty">
          {{ keyword ? '查无此道友，换个关键词再寻' : (activeGrade || activeHall) ? '此品阶/堂口暂无人上榜' : '此榜尚无人上榜' }}
        </p>

        <ul v-else class="rank-list">
          <li
            v-for="(m, idx) in filteredList"
            :key="m.id"
            class="rank-row"
            :class="[
              { 'me': m.me },
              !keyword ? { 'top-1': idx === 0, 'top-2': idx === 1, 'top-3': idx === 2 } : {}
            ]"
          >
            <span class="rank-no" :class="{ medal: idx < 3 && !keyword }">{{ globalRank(m) }}</span>
            <span class="rank-avatar">{{ m.icon || '🧑‍🦲' }}</span>
            <div class="rank-main">
              <h3>
                {{ m.name }}
                <small v-if="m.me" class="me-inline">本座</small>
                <small v-else-if="m.title" class="rank-title">{{ m.title }}</small>
              </h3>
              <p>{{ m.hall }} · 入宗 {{ fmtDate(m.createTime) }}</p>
            </div>
            <span class="realm-pill" :class="realmClass(m.realm)">{{ m.realmFull || m.realm }}</span>
            <div class="rank-nums">
              <span class="power" :class="{ strong: sortBy === 'power' && tier !== 'disciple' }">战力 {{ fmtNum(m.power) }}</span>
              <span class="contrib" :class="{ strong: sortBy === 'contribution' && tier !== 'disciple' }">贡献 {{ fmtNum(m.contribution) }}</span>
            </div>
          </li>
        </ul>
      </section>
    </template>

    <footer class="page-foot">© 2026 寂幽门 · 宗门榜 · 长老执宗，弟子蓄势</footer>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import { fetchHallStats, fetchRank } from '../api/sect'
import { ELDER_MIN_REALM, REALMS, STAGES, realmClass, tierOf } from '../utils/realm'

/** 身份展示顺序（越尊贵越靠前），未在表内的按名称排后面 */
const GRADE_ORDER = ['魔尊', '副宗主', '太上长老', '内门长老', '外门长老', '执法长老',
  '丹殿长老', '内务长老', '堂主', '长老', '圣子', '圣女', '真传弟子', '首席弟子',
  '内门弟子', '外门弟子', '记名弟子', '本座']
const GRADE_ICON = {
  魔尊: '👑', 副宗主: '🌙', 太上长老: '🕊️', 内门长老: '⭐', 外门长老: '🔯',
  圣子: '☀️', 圣女: '🌸', 真传弟子: '🗡️', 内门弟子: '⚔️', 外门弟子: '🛡️',
  记名弟子: '📿', 本座: '🧙'
}

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const members = ref([])
const allMembers = ref([])
const hallStats = ref({})
const activeHall = ref('')
const activeGrade = ref('')
const tier = ref('elder')
const sortBy = ref('power')
const keyword = ref('')
const loading = ref(true)
const refreshing = ref(false)
const error = ref('')

const tierName = computed(() => tier.value === 'elder' ? '长老榜' : '弟子榜')
const tierDesc = computed(() =>
  tier.value === 'elder'
    ? '魔尊执尊，长老治宗 · 太上长老 / 内门长老 / 外门长老 · 按战力/贡献排位'
    : '圣子圣女领衔，真传弟子蓄势 · 内外门弟子皆在此列 · 按修为排位')

const elderCount = computed(() => allMembers.value.filter(m => m.elder).length)
const discipleCount = computed(() => allMembers.value.filter(m => !m.elder).length)

/** 身份分组：只统计当前榜内的身份，供 chips 筛选 */
const gradeStats = computed(() => {
  const counts = {}
  members.value.forEach(m => {
    const key = m.title || '无品阶'
    counts[key] = (counts[key] || 0) + 1
  })
  return Object.entries(counts)
    .map(([key, count]) => ({ key, count, icon: GRADE_ICON[key] || '·' }))
    .sort((a, b) => {
      const ai = GRADE_ORDER.indexOf(a.key)
      const bi = GRADE_ORDER.indexOf(b.key)
      return (ai < 0 ? 99 : ai) - (bi < 0 ? 99 : bi)
    })
})

const filteredList = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return members.value.filter(m => {
    const grade = m.title || '无品阶'
    if (activeGrade.value && grade !== activeGrade.value) return false
    if (activeHall.value && m.hall !== activeHall.value) return false
    if (!kw) return true
    return [m.name, m.realm, m.realmFull, m.stage, m.title, m.hall]
      .some(v => String(v || '').toLowerCase().includes(kw))
  })
})

/** 领奖台按 2 → 1 → 3 名排布，中间最高 */
const podiumSlots = computed(() => {
  if (keyword.value.trim()) return []
  return [1, 0, 2]
    .map(i => ({ m: members.value[i], rank: i + 1 }))
    .filter(s => s.m)
})

const myEntry = computed(() => members.value.find(m => m.me) || null)
const myAllEntry = computed(() => allMembers.value.find(m => m.me) || null)
const myRank = computed(() => members.value.findIndex(m => m.me) + 1)
const myAllRank = computed(() => allMembers.value.findIndex(m => m.me) + 1)

/** 距上一名的差距：弟子榜比修为境界，长老榜按战力/贡献差额 */
const gapText = computed(() => {
  if (!myEntry.value) return ''
  if (myRank.value <= 1) return '已登顶本榜，后来者皆在脚下'
  const ahead = members.value[myRank.value - 2]
  if (!ahead) return ''
  if (tier.value === 'disciple') {
    return `距上一位「${ahead.name}」（${ahead.realmFull || ahead.realm}）尚差一线修为`
  }
  const key = sortBy.value === 'contribution' ? 'contribution' : 'power'
  const label = key === 'contribution' ? '贡献' : '战力'
  const diff = Math.max(0, Number(ahead[key] || 0) - Number(myEntry.value[key] || 0))
  return `距上一位「${ahead.name}」还差 ${fmtNum(diff)} ${label}`
})

/** 领奖台主数值：弟子榜显示修为境界，其余榜显示战力/贡献 */
function boardValue(m) {
  if (tier.value === 'disciple') return m.realmFull || m.realm || '—'
  return sortBy.value === 'contribution' ? fmtNum(m.contribution) : fmtNum(m.power)
}
const boardLabel = computed(() =>
  tier.value === 'disciple' ? '修为境界' : (sortBy.value === 'contribution' ? '宗门贡献' : '战力'))

onMounted(() => load())

async function load(showLoading = true) {
  if (showLoading) loading.value = true
  else refreshing.value = true
  error.value = ''
  try {
    // 同时拉全宗榜：用于辈分计数、以及玩家不在当前榜时的提示
    const [list, halls, all] = await Promise.all([
      fetchRank(props.username, sortBy.value, tier.value),
      fetchHallStats(props.username, tier.value),
      fetchRank(props.username, 'power', 'all')
    ])
    members.value = Array.isArray(list) ? list : []
    allMembers.value = Array.isArray(all) ? all : []
    hallStats.value = halls || {}
  } catch (e) {
    error.value = e.message || '宗门榜加载失败'
    showToast(error.value)
  } finally {
    loading.value = false
    refreshing.value = false
  }
}

function switchTier(key) {
  if (tier.value === key) return
  tier.value = key
  activeHall.value = ''
  activeGrade.value = ''
  load(false)
}

/** 图例按当前榜展示对应境界：长老榜显示炼虚以上，弟子榜显示化神以下 */
const legendRealms = computed(() =>
  tier.value === 'elder' ? REALMS.slice(5) : REALMS.slice(0, 5)
)

function switchSort(key) {
  if (sortBy.value === key) return
  sortBy.value = key
  load(false)
}

/** 即便筛选/搜索，名次仍显示本榜总排名 */
function globalRank(m) {
  const idx = members.value.findIndex(x => x.id === m.id)
  return idx < 0 ? '—' : idx + 1
}

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

.state-panel {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 60px 20px;
  color: var(--text-soft);
  font-size: 13px;
  letter-spacing: 3px;
}

.state-seal {
  width: 46px;
  height: 46px;
  border-radius: 10px;
  display: grid;
  place-items: center;
  font-size: 24px;
  color: #f7e9c4;
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  border: 1px solid var(--gold);
  animation: breathe 1.6s ease-in-out infinite;
}

@keyframes breathe {
  0%, 100% { opacity: .45; transform: scale(.94) rotate(-6deg); }
  50% { opacity: 1; transform: scale(1.04) rotate(-6deg); }
}

/* ===== 我的名次 ===== */
.my-rank {
  display: flex;
  align-items: center;
  gap: 18px;
  margin: 0 32px 18px;
  padding: 16px 20px;
  border: 1px solid rgba(212, 175, 55, .42);
  border-radius: 14px;
  background: linear-gradient(100deg, rgba(140, 15, 29, .28), rgba(12, 8, 18, .82) 62%);
  box-shadow: 0 0 22px rgba(200, 16, 46, .14);
}

.my-rank.off-board { border-color: rgba(196, 154, 92, .25); background: rgba(12, 8, 18, .82); }
.my-seal {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 88px;
  min-width: 88px;
  height: 88px;
  border-radius: 12px;
  border: 1px solid var(--gold);
  background: linear-gradient(145deg, #8c0f1d, #c8102e);
  box-shadow: 0 4px 18px rgba(200, 16, 46, .4), inset 0 0 12px rgba(0, 0, 0, .3);
}
.off-board .my-seal { background: rgba(20, 14, 26, .9); border-style: dashed; }
.my-seal small { font-size: 10px; letter-spacing: 1px; color: rgba(247, 233, 196, .8); }
.my-seal b { font-family: "STKaiti", "KaiTi", serif; font-size: 34px; line-height: 1.1; color: #f7e9c4; }
.my-seal span { font-size: 10px; color: rgba(247, 233, 196, .65); }

.my-info { flex: 1; min-width: 0; }
.my-name { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.my-name h2 { font-family: "STKaiti", "KaiTi", serif; font-size: 20px; letter-spacing: 2px; color: #f3e8d6; margin: 0; }

.me-tag,
.me-inline {
  padding: 2px 9px;
  font-size: 11px;
  font-weight: 400;
  letter-spacing: 1px;
  color: #f7e9c4;
  border: 1px solid var(--gold);
  border-radius: 999px;
  background: rgba(200, 16, 46, .55);
}
.me-inline { margin-left: 8px; vertical-align: middle; }

.my-meta { font-size: 12px; color: var(--text-dim); letter-spacing: 1px; margin: 6px 0 0; }
.my-hint { font-size: 12px; color: rgba(226, 196, 110, .9); letter-spacing: 1px; margin: 6px 0 0; }
.my-nums { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; flex-shrink: 0; }
.my-nums span { font-size: 13px; color: var(--text-soft); }
.my-nums .strong { color: #ff8a95; font-weight: 700; }

.jump-btn {
  padding: 9px 16px;
  border: 1px solid var(--gold);
  border-radius: 9px;
  background: linear-gradient(135deg, rgba(140, 15, 29, .85), rgba(200, 16, 46, .65));
  color: #f7e9c4;
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 1px;
  cursor: pointer;
  flex-shrink: 0;
}
.jump-btn:hover { box-shadow: 0 0 14px rgba(200, 16, 46, .45); }

/* ===== 榜别 / 维度 / 工具 ===== */
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
  margin: 0 32px 10px;
}

.tier-switch,
.board-switch {
  display: inline-flex;
  padding: 3px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: rgba(12, 8, 18, .72);
}

.tier-switch button,
.board-switch button {
  padding: 7px 16px;
  border: 0;
  border-radius: 999px;
  background: transparent;
  color: var(--text-soft);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: color .18s, background .18s;
}
.tier-switch button small { font-size: 10px; opacity: .75; letter-spacing: 0; }
.board-fixed {
  display: inline-flex;
  align-items: center;
  padding: 7px 18px;
  color: #f7e9c4;
  font-size: 13px;
  letter-spacing: 2px;
  border-radius: 999px;
  background: rgba(140, 15, 29, .35);
  border: 1px solid var(--gold);
}
.tier-switch button.active,
.board-switch button.active {
  color: #f7e9c4;
  background: linear-gradient(135deg, rgba(140, 15, 29, .85), rgba(200, 16, 46, .65));
  box-shadow: 0 0 12px rgba(200, 16, 46, .35);
}

.tools { display: flex; gap: 8px; align-items: center; }
.search-input {
  width: 230px;
  padding: 8px 14px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--card-input);
  color: var(--text);
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 1px;
  outline: none;
}
.search-input:focus { border-color: var(--gold); }
.search-input::placeholder { color: var(--text-dim); }

.refresh-btn {
  width: 34px;
  height: 34px;
  border: 1px solid var(--border);
  border-radius: 50%;
  background: var(--card-input);
  color: var(--gold-soft);
  font-size: 17px;
  cursor: pointer;
}
.refresh-btn:hover { border-color: var(--gold); }
.refresh-btn:disabled { opacity: .5; cursor: wait; }

/* 小层次图例 */
.stage-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 16px;
  margin: 0 32px 16px;
  padding: 10px 14px;
  border: 1px dashed rgba(196, 154, 92, .28);
  border-radius: 10px;
  background: rgba(10, 7, 15, .45);
}
.stage-legend-item { display: inline-flex; align-items: baseline; gap: 6px; font-size: 11px; }
.stage-legend-item b { letter-spacing: 1px; }
.stage-legend-item small { color: var(--text-dim); letter-spacing: 0; }

/* 身份筛选 */
.grade-wrap { padding: 0 32px 6px; }
.grade-tabs { display: flex; flex-wrap: wrap; gap: 6px; }
.grade-tab {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 5px 12px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: rgba(12, 8, 18, .72);
  color: var(--text-soft);
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  cursor: pointer;
  transition: color .18s, border-color .18s, background .18s;
}
.grade-tab:hover { color: var(--gold-soft); border-color: var(--gold); }
.grade-tab.active {
  color: #f7e9c4;
  border-color: var(--gold);
  background: linear-gradient(135deg, rgba(140, 15, 29, .7), rgba(200, 16, 46, .5));
  box-shadow: 0 0 12px rgba(200, 16, 46, .28);
}
.grade-tab small { font-size: 10px; color: var(--text-dim); letter-spacing: 0; }
.grade-tab.active small { color: rgba(247, 233, 196, .8); }

/* ===== 前三领奖台 ===== */
.podium {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 14px;
  margin: 0 32px 20px;
  padding: 18px 12px 0;
}

.podium-slot {
  position: relative;
  width: 210px;
  padding: 14px 12px 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  border: 1px solid var(--border);
  border-radius: 14px 14px 4px 4px;
  background: rgba(10, 7, 15, .82);
  transition: transform .2s, box-shadow .2s;
}
.podium-slot:hover { transform: translateY(-3px); }
.podium-slot.p-1 {
  order: 2;
  min-height: 182px;
  border-color: var(--gold);
  background: linear-gradient(180deg, rgba(140, 15, 29, .55), rgba(10, 7, 15, .9) 78%);
  box-shadow: 0 0 26px rgba(200, 16, 46, .28);
}
.podium-slot.p-2 { order: 1; min-height: 156px; }
.podium-slot.p-3 { order: 3; min-height: 140px; }

.podium-crown { font-size: 22px; line-height: 1; }
.podium-avatar {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 26px;
  background: rgba(0, 0, 0, .4);
  border: 1px solid var(--border-strong);
}
.p-1 .podium-avatar { border-color: var(--gold); box-shadow: 0 0 14px rgba(212, 175, 55, .35); }
.podium-slot h3 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 16px;
  letter-spacing: 1px;
  color: #f3e8d6;
  margin: 2px 0 0;
  white-space: nowrap;
}
.podium-slot h3 em { font-style: normal; font-size: 10px; color: var(--gold-soft); margin-left: 4px; }
.podium-realm { font-size: 11px; letter-spacing: 1px; color: var(--text-soft); }
.podium-value { font-family: "STKaiti", "KaiTi", serif; font-size: 19px; color: #ff8a95; margin-top: 4px; }
.p-1 .podium-value { color: #ffd76a; font-size: 22px; }
.podium-label { font-size: 10px; letter-spacing: 2px; color: var(--text-dim); }

/* ===== 堂口筛选 ===== */
.tabs-wrap { padding: 0 32px 24px; }
.tabs { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 14px; }
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
.empty.error { color: #ff8a95; }

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
  background: rgba(10, 7, 15, .78);
  transition: background .15s;
}
.rank-row + .rank-row { border-top: 1px solid var(--border); }
.rank-row:hover { background: rgba(28, 18, 36, .65); }
.rank-row.top-1 { background: linear-gradient(90deg, rgba(200, 16, 46, .25), rgba(12, 8, 18, .7)); }
.rank-row.top-2 { background: linear-gradient(90deg, rgba(200, 16, 46, .16), rgba(12, 8, 18, .7)); }
.rank-row.top-3 { background: linear-gradient(90deg, rgba(200, 16, 46, .10), rgba(12, 8, 18, .7)); }
.rank-row.me { border-left: 3px solid var(--gold); }

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
.rank-main h3 { font-size: 15px; color: #f3e8d6; letter-spacing: 1px; margin: 0 0 3px; }
.rank-title { margin-left: 8px; font-size: 11px; font-weight: 400; letter-spacing: 1px; color: rgba(212, 175, 55, .8); }
.rank-main p { font-size: 12px; color: var(--text-dim); letter-spacing: 1px; margin: 0; }

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

.rank-nums { display: flex; flex-direction: column; align-items: flex-end; gap: 2px; flex-shrink: 0; }
.power { font-size: 13px; letter-spacing: 1px; color: rgba(226, 58, 78, .9); }
.contrib { font-size: 11px; letter-spacing: 1px; color: rgba(212, 175, 55, .6); }
.power.strong, .contrib.strong { font-weight: 700; text-decoration: underline; text-underline-offset: 3px; }

/* ===== 页脚 / 响应式 ===== */
.page-foot {
  padding: 16px 32px 20px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .5);
  border-top: 1px solid var(--border);
}

@media (max-width: 900px) {
  .podium-slot { width: 30%; }
  .my-rank { flex-wrap: wrap; }
  .my-nums { flex-direction: row; gap: 14px; }
}

@media (max-width: 780px) {
  .hero { padding: 26px 18px 18px; }
  .hero h1 { font-size: 21px; letter-spacing: 2px; }
  .my-rank { margin: 0 18px 14px; }
  .my-seal { width: 70px; min-width: 70px; height: 70px; }
  .toolbar { margin: 0 18px 10px; }
  .stage-legend { margin: 0 18px 14px; }
  .grade-wrap { padding: 0 18px 6px; }
  .search-input { width: 150px; }
  .podium { margin: 0 18px 18px; padding: 14px 0 0; gap: 6px; }
  .podium-slot { width: 32%; padding: 10px 5px 12px; min-height: 120px !important; }
  .podium-crown { font-size: 16px; }
  .podium-avatar { width: 36px; height: 36px; font-size: 18px; }
  .podium-slot h3 { font-size: 12px; }
  .podium-value { font-size: 14px !important; }
  .tabs-wrap { padding: 0 18px 20px; }
  .rank-main p { display: none; }
  .contrib { display: none; }
}
</style>
