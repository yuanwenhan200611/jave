<template>
  <div class="page">
    <SectNav active="cultivation" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 魔功殿名 -->
    <header class="hero">
      <span class="hero-seal">魔</span>
      <div>
        <h1>魔功殿</h1>
        <p class="hero-desc">修为之道，取之于人，夺之于天</p>
      </div>
    </header>

    <!-- 修为总览 -->
    <section class="overview" v-if="info">
      <div class="ov-left">
        <div class="ov-realm-row">
          <span class="ov-realm-badge">{{ info.realm }}</span>
          <span class="ov-label">当前修为</span>
          <span class="ov-cultivation">{{ formatNum(info.cultivation) }}</span>
        </div>
        <div class="ov-bar-wrap">
          <div class="ov-bar">
            <div class="ov-bar-fill" :style="{ width: progressPct + '%' }"></div>
          </div>
          <span class="ov-bar-text">
            <template v-if="info.nextRealm">
              距「{{ info.nextRealm }}」还差 {{ formatNum(Math.max(0, info.nextThreshold - info.cultivation)) }} 修为
            </template>
            <template v-else>已至大道尽头——魔尊之上，再无境界</template>
          </span>
        </div>
      </div>
      <div class="ov-right">
        <div class="ov-balance">
          <span class="ov-b-icon">💎</span>
          <div>
            <b>灵石</b>
            <small>{{ formatNum(info.stonesBalance) }}</small>
          </div>
        </div>
        <div class="ov-balance">
          <span class="ov-b-icon">🪙</span>
          <div>
            <b>贡献值</b>
            <small>{{ formatNum(info.contributionBalance) }}</small>
          </div>
        </div>
      </div>
    </section>

    <p v-if="error" class="empty">{{ error }}</p>
    <p v-else-if="!loading && !info" class="empty">魔功殿殿门紧闭，稍后再来</p>

    <!-- 五法门 -->
    <section class="methods" v-if="info">
      <h2 class="section-title">—— 修炼法门 ——</h2>
      <div class="method-grid">
        <article
          v-for="m in info.methods"
          :key="m.key"
          class="method-card"
          :class="'risk-' + riskLevel(m)"
        >
          <div class="method-head">
            <span class="method-icon">{{ m.icon }}</span>
            <div class="method-name-wrap">
              <h3>{{ m.name }}</h3>
              <span class="risk-tag" :class="'rt-' + riskLevel(m)">{{ m.riskText }}</span>
            </div>
          </div>
          <p class="method-desc">{{ m.desc }}</p>
          <ul class="method-meta">
            <li v-if="m.costStones > 0"><b>消耗</b>灵石 {{ m.costStones }}</li>
            <li v-if="m.costContribution > 0"><b>消耗</b>贡献值 {{ m.costContribution }}</li>
            <li v-else-if="m.costStones === 0"><b>消耗</b>分文不取</li>
            <li><b>调息</b>{{ m.cooldownSeconds }} 秒</li>
          </ul>
          <button
            class="method-btn"
            type="button"
            :disabled="remain(m) > 0 || practicing"
            @click="onPractice(m)"
          >
            {{ practicing === m.key ? '修 炼 中……' : (remain(m) > 0 ? `调息 ${remain(m)} 秒` : '修 炼') }}
          </button>
        </article>
      </div>
    </section>

    <!-- 修炼记录 -->
    <section class="logs" v-if="info">
      <h2 class="section-title">—— 修炼手札 ——</h2>
      <p v-if="!info.logs.length" class="empty">手札空空——你尚未吞吐过一口魔气</p>
      <ul v-else class="log-list">
        <li v-for="(l, i) in info.logs" :key="i" class="log-row" :class="{ bad: l.outcome === 'backlash' }">
          <span class="log-delta" :class="l.delta >= 0 ? 'up' : 'down'">
            {{ l.delta >= 0 ? '+' : '' }}{{ formatNum(l.delta) }}
          </span>
          <div class="log-main">
            <h3>{{ l.methodName }}<small class="log-outcome" :class="'oc-' + l.outcome">{{ l.outcomeText }}</small></h3>
            <p>{{ l.story }}</p>
          </div>
          <span class="log-time">{{ shortTime(l.createTime) }}</span>
        </li>
      </ul>
    </section>

    <footer class="page-foot">© 2026 逆天魔宗 · 魔功殿 · 逆天而行，后果自负</footer>

    <!-- 修炼结果弹层 -->
    <div v-if="result" class="detail-mask" @click.self="result = null">
      <div class="detail-panel result-panel" :class="'oc-bg-' + result.outcome">
        <button class="detail-close" type="button" @click="result = null">✕</button>
        <p class="result-label">—— 修 炼 结 果 ——</p>
        <div class="result-head">
          <span class="result-icon">{{ result.icon }}</span>
          <div>
            <h2>{{ result.methodName }}</h2>
            <span class="result-outcome" :class="'oc-' + result.outcome">{{ result.outcomeText }}</span>
          </div>
          <span class="result-delta" :class="result.delta >= 0 ? 'up' : 'down'">
            修为 {{ result.delta >= 0 ? '+' : '' }}{{ formatNum(result.delta) }}
          </span>
        </div>

        <div v-if="result.breakthrough" class="breakthrough">
          ✦ 突破 ✦
          <p>
            咔——道基之上裂开一道缝隙，磅礴魔气倒灌而入！<br>
            你一步跨入【{{ result.toRealm }}】，从此天地更大了。
          </p>
        </div>

        <p class="result-story">{{ result.story }}</p>

        <div class="result-after">
          <div><small>当前修为</small><b>{{ formatNum(result.cultivation) }}</b></div>
          <div><small>境界</small><b>{{ result.realm }}</b></div>
          <div><small>灵石余</small><b>{{ formatNum(result.stonesBalance) }}</b></div>
          <div><small>贡献余</small><b>{{ formatNum(result.contributionBalance) }}</b></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { useToast } from '../composables/useToast'
import { fetchCultivationInfo, practice } from '../api/cultivation'

const props = defineProps({
  username: { type: String, default: '道友' }
})

const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const loading = ref(false)
const error = ref('')
const info = ref(null)

// 修炼状态与结果弹层
const practicing = ref(false)
const result = ref(null)

// 冷却倒计时：methodKey -> 恢复时间戳（毫秒）
const cooldownEnds = ref({})
const now = ref(Date.now())
let timer = null

const progressPct = computed(() => {
  const d = info.value
  if (!d) return 0
  if (!d.nextRealm || !d.nextThreshold) return 100
  const base = d.realmThreshold || 0
  const span = d.nextThreshold - base
  if (span <= 0) return 100
  return Math.min(100, Math.max(0, Math.round(((d.cultivation - base) / span) * 100)))
})

onMounted(async () => {
  timer = setInterval(() => { now.value = Date.now() }, 1000)
  await load()
})

onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})

async function load() {
  loading.value = true
  error.value = ''
  try {
    const data = await fetchCultivationInfo(props.username)
    info.value = data
    // 以后端返回的剩余秒数重建本地倒计时
    const ends = {}
    for (const m of data.methods || []) {
      if (m.remainSeconds > 0) {
        ends[m.key] = Date.now() + m.remainSeconds * 1000
      }
    }
    cooldownEnds.value = ends
  } catch (e) {
    error.value = e.message || '魔功殿数据加载失败'
  } finally {
    loading.value = false
  }
}

function remain(m) {
  const end = cooldownEnds.value[m.key]
  if (!end) return 0
  return Math.max(0, Math.ceil((end - now.value) / 1000))
}

function riskLevel(m) {
  if (m.riskText === '禁忌') return 3
  if (m.riskText === '大险') return 2
  if (m.riskText === '小险') return 1
  return 0
}

/** 修炼一门魔功：掷结果 → 弹结果层 → 刷新修为与冷却 */
async function onPractice(m) {
  if (practicing.value) return
  practicing.value = true
  try {
    const res = await practice(m.key, props.username)
    result.value = res
    cooldownEnds.value = {
      ...cooldownEnds.value,
      [m.key]: Date.now() + (res.cooldownSeconds || m.cooldownSeconds) * 1000
    }
    // 轻量刷新总览（不重置倒计时）
    load()
  } catch (e) {
    showToast(e.message || '修炼失败，天机紊乱')
  } finally {
    practicing.value = false
  }
}

function formatNum(n) {
  return Number(n || 0).toLocaleString('zh-CN')
}

function shortTime(t) {
  if (!t) return ''
  const d = new Date(t)
  if (Number.isNaN(d.getTime())) return ''
  const pad = x => String(x).padStart(2, '0')
  return `${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
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

/* ===== 魔功殿名 ===== */
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

/* ===== 修为总览 ===== */
.overview {
  display: flex;
  align-items: center;
  gap: 20px;
  margin: 0 32px 20px;
  padding: 18px 22px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background:
    radial-gradient(120% 100% at 0% 0%, rgba(200, 16, 46, .14), transparent 55%),
    rgba(10, 7, 15, .80);
}

.ov-left { flex: 1; min-width: 0; }

.ov-realm-row {
  display: flex;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 12px;
}

.ov-realm-badge {
  padding: 3px 14px;
  border-radius: 999px;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 16px;
  letter-spacing: 3px;
  color: #f7e9c4;
  background: linear-gradient(135deg, #8c0f1d, #c8102e);
  border: 1px solid rgba(212, 175, 55, .55);
  box-shadow: 0 0 12px rgba(200, 16, 46, .4);
}

.ov-label { font-size: 12px; letter-spacing: 2px; color: var(--text-soft); }

.ov-cultivation {
  font-size: 24px;
  font-weight: 700;
  letter-spacing: 1px;
  color: var(--gold-soft);
  text-shadow: 0 0 14px rgba(212, 175, 55, .35);
}

.ov-bar-wrap { display: flex; align-items: center; gap: 14px; }

.ov-bar {
  flex: 1;
  height: 10px;
  border-radius: 999px;
  background: rgba(12, 8, 18, .9);
  border: 1px solid var(--border);
  overflow: hidden;
}

.ov-bar-fill {
  height: 100%;
  border-radius: 999px;
  background: linear-gradient(90deg, #7a0f1d, #c8102e 60%, #e23a4e);
  box-shadow: 0 0 10px rgba(200, 16, 46, .55);
  transition: width .6s ease;
}

.ov-bar-text {
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .7);
  white-space: nowrap;
}

.ov-right { display: flex; gap: 12px; flex-shrink: 0; }

.ov-balance {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 14px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(12, 8, 18, .72);
}

.ov-b-icon { font-size: 20px; }

.ov-balance b {
  display: block;
  font-size: 11px;
  letter-spacing: 2px;
  color: var(--text-soft);
  font-weight: 400;
}

.ov-balance small {
  display: block;
  font-size: 15px;
  color: var(--gold-soft);
  letter-spacing: 1px;
}

/* ===== 法门 ===== */
.section-title {
  text-align: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 16px;
  font-weight: 400;
  letter-spacing: 6px;
  color: rgba(212, 175, 55, .6);
  margin: 4px 0 14px;
}

.methods { padding: 0 32px 8px; }

.method-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 14px;
}

.method-card {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 16px 18px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background:
    radial-gradient(130% 90% at 50% -10%, rgba(200, 16, 46, .10), transparent 60%),
    rgba(10, 7, 15, .82);
  transition: transform .15s, border-color .18s, box-shadow .18s;
}

.method-card:hover {
  transform: translateY(-2px);
  border-color: var(--border-strong);
  box-shadow: 0 10px 28px rgba(0, 0, 0, .45);
}

.method-card.risk-1 { border-left: 3px solid rgba(212, 175, 55, .5); }
.method-card.risk-2 { border-left: 3px solid rgba(226, 58, 78, .6); }
.method-card.risk-3 { border-left: 3px solid #e23a4e; box-shadow: inset 0 0 24px rgba(200, 16, 46, .10); }

.method-head {
  display: flex;
  align-items: center;
  gap: 10px;
}

.method-icon {
  width: 40px;
  height: 40px;
  display: grid;
  place-items: center;
  font-size: 22px;
  border-radius: 10px;
  background: rgba(12, 8, 18, .85);
  border: 1px solid var(--border-strong);
  flex-shrink: 0;
}

.method-name-wrap { flex: 1; min-width: 0; display: flex; align-items: center; gap: 8px; }

.method-head h3 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 17px;
  letter-spacing: 2px;
  color: #f3e8d6;
  margin: 0;
}

.risk-tag {
  padding: 1px 8px;
  font-size: 11px;
  letter-spacing: 1px;
  border-radius: 999px;
  color: var(--text-soft);
  border: 1px solid var(--border);
  flex-shrink: 0;
}

.rt-1 { color: var(--gold-soft); border-color: rgba(212, 175, 55, .45); }
.rt-2 { color: #f0a5ad; border-color: rgba(226, 58, 78, .5); }
.rt-3 { color: #ffd9dd; background: rgba(200, 16, 46, .3); border-color: rgba(226, 58, 78, .8); }

.method-desc {
  font-size: 13px;
  line-height: 1.8;
  color: var(--text-soft);
  margin: 0;
  min-height: 46px;
}

.method-meta {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 6px 14px;
  font-size: 12px;
  color: var(--text);
  letter-spacing: 1px;
}

.method-meta b {
  font-weight: 400;
  color: var(--text-dim);
  margin-right: 4px;
}

.method-btn {
  margin-top: auto;
  padding: 10px 0;
  border: 1px solid rgba(212, 175, 55, .55);
  border-radius: 10px;
  cursor: pointer;
  background: linear-gradient(135deg, #8c0f1d 0%, #c8102e 60%, #a5142a 100%);
  color: #f7e9c4;
  font-family: inherit;
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 4px;
  box-shadow: 0 4px 16px rgba(200, 16, 46, .35), inset 0 0 10px rgba(0, 0, 0, .25);
  transition: transform .15s, filter .2s, opacity .2s;
}

.method-btn:hover:not(:disabled) { transform: translateY(-1px); filter: brightness(1.12); }
.method-btn:active:not(:disabled) { transform: translateY(0); }
.method-btn:disabled { opacity: .55; cursor: not-allowed; }

/* ===== 修炼记录 ===== */
.logs { padding: 14px 32px 8px; }

.empty {
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
  padding: 18px 0;
}

.log-list {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
}

.log-row {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 11px 16px;
  background: rgba(10, 7, 15, .78);
}

.log-row + .log-row { border-top: 1px solid var(--border); }
.log-row:hover { background: rgba(28, 18, 36, .65); }
.log-row.bad { background: rgba(60, 10, 22, .35); }

.log-delta {
  width: 76px;
  flex-shrink: 0;
  text-align: center;
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 1px;
}

.log-delta.up { color: var(--gold-soft); text-shadow: 0 0 10px rgba(212, 175, 55, .3); }
.log-delta.down { color: var(--danger); text-shadow: 0 0 10px rgba(255, 77, 94, .3); }

.log-main { flex: 1; min-width: 0; }

.log-main h3 {
  font-size: 14px;
  letter-spacing: 1px;
  color: #f3e8d6;
  margin: 0 0 2px;
}

.log-outcome {
  display: inline-block;
  margin-left: 8px;
  padding: 0 8px;
  font-size: 11px;
  border-radius: 999px;
  vertical-align: middle;
}

.oc-great { color: #ffe9b8; background: rgba(200, 16, 46, .45); border: 1px solid rgba(212, 175, 55, .6); }
.oc-good { color: var(--gold-soft); background: rgba(212, 175, 55, .14); border: 1px solid rgba(212, 175, 55, .4); }
.oc-backlash { color: #ffd9dd; background: rgba(90, 12, 40, .6); border: 1px solid rgba(226, 58, 78, .7); }

.log-main p {
  font-size: 12px;
  line-height: 1.7;
  color: var(--text-soft);
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.log-time {
  font-size: 12px;
  color: var(--text-dim);
  letter-spacing: 1px;
  flex-shrink: 0;
}

/* ===== 结果弹层 ===== */
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

.result-panel.oc-bg-great {
  border-color: rgba(212, 175, 55, .9);
  box-shadow: 0 0 0 1px rgba(212, 175, 55, .35), 0 0 70px rgba(212, 175, 55, .3), 0 30px 80px rgba(0, 0, 0, .7);
}

.result-panel.oc-bg-backlash {
  border-color: rgba(226, 58, 78, .85);
  box-shadow: 0 0 0 1px rgba(200, 16, 46, .35), 0 0 70px rgba(200, 16, 46, .4), 0 30px 80px rgba(0, 0, 0, .7);
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

.result-label {
  text-align: center;
  font-size: 11px;
  letter-spacing: 6px;
  color: rgba(212, 175, 55, .55);
  margin: 0 0 16px;
}

.result-head {
  display: flex;
  align-items: center;
  gap: 14px;
  padding-right: 34px;
}

.result-icon { font-size: 38px; line-height: 1.1; flex-shrink: 0; }

.result-head h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 22px;
  letter-spacing: 2px;
  color: #f3e8d6;
  margin: 0 0 6px;
}

.result-outcome {
  display: inline-block;
  padding: 1px 10px;
  font-size: 12px;
  letter-spacing: 2px;
  border-radius: 999px;
}

.result-delta {
  margin-left: auto;
  font-size: 20px;
  font-weight: 700;
  letter-spacing: 1px;
  flex-shrink: 0;
}

.result-delta.up { color: var(--gold-soft); text-shadow: 0 0 16px rgba(212, 175, 55, .4); }
.result-delta.down { color: var(--danger); text-shadow: 0 0 16px rgba(255, 77, 94, .4); }

.breakthrough {
  margin: 16px 0 0;
  padding: 14px 16px;
  text-align: center;
  border: 1px solid rgba(212, 175, 55, .7);
  border-radius: 12px;
  background: linear-gradient(135deg, rgba(140, 15, 29, .5), rgba(212, 175, 55, .12));
  box-shadow: 0 0 24px rgba(212, 175, 55, .25);
}

.breakthrough {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 16px;
  letter-spacing: 4px;
  color: #ffe9b8;
  text-shadow: 0 0 14px rgba(212, 175, 55, .5);
  animation: bt-pulse 1.6s ease-in-out infinite;
}

.breakthrough p {
  margin: 8px 0 0;
  font-size: 14px;
  letter-spacing: 1px;
  line-height: 1.9;
  color: #f3e8d6;
  text-shadow: none;
  animation: none;
}

@keyframes bt-pulse {
  0%, 100% { box-shadow: 0 0 24px rgba(212, 175, 55, .25); }
  50% { box-shadow: 0 0 40px rgba(212, 175, 55, .5); }
}

.result-story {
  margin: 16px 0;
  padding: 14px 16px;
  font-size: 14px;
  line-height: 2;
  color: #f3e8d6;
  background: rgba(200, 16, 46, .12);
  border: 1px solid rgba(200, 16, 46, .35);
  border-radius: 12px;
}

.result-after {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
}

.result-after div {
  text-align: center;
  padding: 10px 6px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: rgba(12, 8, 18, .72);
}

.result-after small {
  display: block;
  font-size: 11px;
  letter-spacing: 1px;
  color: var(--text-dim);
  margin-bottom: 4px;
}

.result-after b {
  font-size: 14px;
  color: var(--gold-soft);
  letter-spacing: 1px;
}

/* ===== 页脚 / 响应式 ===== */
.page-foot {
  padding: 16px 32px 20px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .5);
  border-top: 1px solid var(--border);
  margin-top: 14px;
}

@media (max-width: 780px) {
  .hero { padding: 26px 18px 18px; }
  .hero h1 { font-size: 21px; letter-spacing: 2px; }
  .overview { flex-direction: column; align-items: stretch; margin: 0 18px 16px; }
  .ov-right { justify-content: space-between; }
  .methods, .logs { padding-left: 18px; padding-right: 18px; }
  .method-grid { grid-template-columns: 1fr; }
  .log-time { display: none; }
  .result-after { grid-template-columns: repeat(2, 1fr); }
  .result-delta { margin-left: 0; }
}
</style>
