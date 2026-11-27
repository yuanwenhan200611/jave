<template>
  <div class="page">
    <SectNav active="market" :username="username" @nav="k => emit('nav', k)" @logout="emit('logout')" />

    <!-- 坊市招牌 + 灵石池 -->
    <header class="hero">
      <div class="hero-side" aria-hidden="true">
        <span class="hero-rune">童</span><span class="hero-rune">叟</span><span class="hero-rune">无</span><span class="hero-rune">欺</span>
      </div>
      <div class="hero-core">
        <span class="hero-seal">市</span>
        <div class="hero-text">
          <h1>坊 市</h1>
          <p class="hero-desc">万宝流转 · 灵石到位，什么都能谈</p>
        </div>
        <div class="treasury" title="当前可用灵石">
          <span class="treasury-label">灵石池</span>
          <span class="treasury-num">{{ fmtNum(stonesAvailable) }}</span>
          <span class="treasury-unit">灵石</span>
        </div>
      </div>
      <div class="hero-side right" aria-hidden="true">
        <span class="hero-rune">买</span><span class="hero-rune">卖</span><span class="hero-rune">随</span><span class="hero-rune">心</span>
      </div>
    </header>

    <!-- 分类摊位 -->
    <section class="tabs-wrap">
      <div class="tabs">
        <button
          v-for="c in categories"
          :key="c.key"
          type="button"
          class="tab"
          :class="{ active: c.key === activeCategory }"
          @click="switchCategory(c.key)"
        >
          <span class="tab-icon">{{ c.icon }}</span>{{ c.label }}
          <small v-if="c.count" class="tab-count">{{ c.count }}</small>
        </button>
      </div>

      <p v-if="error" class="empty">{{ error }}</p>
      <p v-else-if="loading" class="empty">掌灯看货中……</p>
      <p v-else-if="!items.length" class="empty">此摊货已售罄，稍后再来（摊主正在补货）</p>

      <!-- 货架 -->
      <ul v-else class="goods-grid">
        <li v-for="item in items" :key="item.id" class="goods-card" :class="'g-' + (item.rarity || 'common')">
          <div class="goods-head">
            <span class="goods-icon">{{ item.icon || '📦' }}</span>
            <div class="goods-title-box">
              <h3 class="goods-title">{{ item.title }}</h3>
              <div class="goods-tags">
                <span v-if="item.grade" class="grade-badge">{{ item.grade }}</span>
                <span class="type-tag">{{ typeLabel(item.itemType) }}</span>
                <span class="rarity-tag" :class="'r-' + (item.rarity || 'common')">{{ rarityText(item.rarity) }}</span>
              </div>
            </div>
          </div>
          <p class="goods-desc">{{ item.description }}</p>
          <p class="goods-seller">
            <span v-if="item.sellerType === 'user'" class="private-tag">道友私摊</span>
            摊主 · {{ item.seller }}
          </p>
          <div class="goods-foot">
            <span class="goods-price"><i>💎</i>{{ fmtNum(item.price) }}</span>
            <button
              v-if="item.mine"
              type="button"
              class="buy-btn self"
              disabled
            >自家摊位</button>
            <button
              v-else
              type="button"
              class="buy-btn"
              :disabled="buyingId === item.id || stonesAvailable < item.price"
              @click="buy(item)"
            >
              {{ buyingId === item.id ? '验货中…' : (stonesAvailable < item.price ? '灵石不足' : '买下') }}
            </button>
          </div>
        </li>
      </ul>
    </section>

    <!-- 我的摊位（玩家自行挂单） -->
    <section v-if="myListings.length" class="my-stall-wrap">
      <div class="section-head">
        <h2>我的摊位</h2>
        <p class="section-sub">自家挂出的私摊，未售出可随时撤单收回；游方散修常来捡漏，标价别太狠</p>
      </div>
      <ul class="stall-list">
        <li v-for="s in myListings" :key="s.id" class="stall-row">
          <span class="sell-icon">{{ s.icon }}</span>
          <span class="stall-title">{{ s.title }}</span>
          <span class="rarity-tag" :class="'r-' + (s.rarity || 'common')">{{ rarityText(s.rarity) }}</span>
          <span class="stall-price"><i>💎</i>{{ fmtNum(s.price) }}</span>
          <span class="stall-est">牙人估 {{ fmtNum(s.estimate) }}</span>
          <button type="button" class="cancel-btn" :disabled="cancelingId === s.id" @click="cancelStall(s)">
            {{ cancelingId === s.id ? '撤摊中…' : '撤单收回' }}
          </button>
        </li>
      </ul>
    </section>

    <!-- 寄售回购 / 自行挂单 -->
    <section class="sell-wrap">
      <div class="section-head">
        <h2>寄售货栈</h2>
        <p class="section-sub">可直接卖给牙人换灵石，或自行标价摆私摊——卖出去的，可就赎不回来了</p>
      </div>
      <p v-if="!sellable.length" class="empty small">
        储物袋里没有可寄售的宝贝 —— <span class="goto" @click="emit('nav', 'secret')">去秘境碰碰运气 →</span>
      </p>
      <ul v-else class="sell-list">
        <li v-for="s in sellable" :key="s.id" class="sell-card" :class="'g-' + (s.rarity || 'common')">
          <span class="sell-icon">{{ s.icon }}</span>
          <div class="sell-body">
            <h4>{{ s.name }}</h4>
            <div class="sell-tags">
              <span class="type-tag">{{ s.typeLabel }}</span>
              <span class="rarity-tag" :class="'r-' + (s.rarity || 'common')">{{ rarityText(s.rarity) }}</span>
            </div>
          </div>
          <div class="sell-act">
            <span class="sell-price"><i>💎</i>{{ fmtNum(s.estimate) }}</span>
            <div class="stall-form">
              <input
                v-model.number="priceInputs[s.id]"
                class="price-input"
                type="number"
                min="1"
                :title="`牙人估价 ${s.estimate}，可标 ${Math.max(10, Math.round(s.estimate * 0.5))} ~ ${Math.round(s.estimate * 3)} 灵石`"
                aria-label="挂单标价"
              >
              <button
                type="button"
                class="list-btn"
                :disabled="listingId === s.id"
                @click="listStall(s)"
              >{{ listingId === s.id ? '摆摊中…' : '挂单' }}</button>
            </div>
            <button type="button" class="sell-btn" :disabled="sellingId === s.id" @click="sell(s)">
              {{ sellingId === s.id ? '过秤中…' : '卖给牙人' }}
            </button>
          </div>
        </li>
      </ul>
    </section>

    <!-- 交易手札 -->
    <section class="log-wrap">
      <div class="section-head">
        <h2>交易手札</h2>
        <p class="section-sub">买进卖出，皆有账可查</p>
      </div>
      <p v-if="!orders.length" class="empty small">还没在坊市开过张</p>
      <ul v-else class="log-list">
        <li v-for="o in orders" :key="o.id" class="log-row">
          <span class="log-tag" :class="o.tradeType === 'buy' ? 'tag-buy' : 'tag-sell'">
            {{ o.tradeType === 'buy' ? '购入' : '卖出' }}
          </span>
          <span class="log-title">{{ o.title }}</span>
          <span class="log-who">{{ o.counterparty }}</span>
          <span class="log-price" :class="o.tradeType === 'buy' ? 'minus' : 'plus'">
            {{ o.tradeType === 'buy' ? '-' : '+' }}{{ fmtNum(o.price) }} 灵石
          </span>
        </li>
      </ul>
    </section>

    <footer class="page-foot">© 2026 寂幽门 · 坊市 · 灵石一响，好货登场</footer>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import SectNav from './SectNav.vue'
import { fetchMarketList, fetchMarketOrders, buyMarketItem, sellMarketItem, listMarketItem, cancelMarketItem } from '../api/market'
import { useToast } from '../composables/useToast'

const props = defineProps({
  username: { type: String, default: '' }
})
const emit = defineEmits(['nav', 'logout'])

const { showToast } = useToast()

const loading = ref(true)
const error = ref('')
const stonesAvailable = ref(0)
const items = ref([])
const sellable = ref([])
const orders = ref([])
const myListings = ref([])
const priceInputs = ref({})
const categories = ref([
  { key: 'all', label: '全部货架', icon: '🏮', count: 0 },
  { key: 'artifact', label: '法宝', icon: '⚔️', count: 0 },
  { key: 'technique', label: '功法', icon: '📕', count: 0 },
  { key: 'divine_ability', label: '神通', icon: '👁️', count: 0 },
  { key: 'pill', label: '丹药', icon: '💊', count: 0 }
])
const activeCategory = ref('all')
const buyingId = ref(0)
const sellingId = ref(0)
const listingId = ref(0)
const cancelingId = ref(0)

const RARITY_TEXT = {
  common: '凡品',
  uncommon: '精品',
  rare: '珍品',
  epic: '极品',
  legendary: '传说'
}
const TYPE_TEXT = {
  artifact: '法宝',
  technique: '功法',
  divine_ability: '神通',
  pill: '丹药',
  fragment: '残篇'
}

function rarityText(r) {
  return RARITY_TEXT[r] || '凡品'
}

function typeLabel(t) {
  return TYPE_TEXT[t] || '奇物'
}

function fmtNum(n) {
  const v = Number(n || 0)
  return v.toLocaleString('zh-CN')
}

async function load(category = activeCategory.value) {
  loading.value = true
  error.value = ''
  try {
    const [market, log] = await Promise.all([
      fetchMarketList(props.username, category),
      fetchMarketOrders(props.username, 20).catch(() => [])
    ])
    stonesAvailable.value = market?.stonesAvailable ?? 0
    items.value = market?.items || []
    sellable.value = market?.sellable || []
    myListings.value = market?.myListings || []
    // 挂单输入框默认填牙人估价，已有输入的保留玩家改过的价格
    const nextPrices = {}
    for (const s of sellable.value) {
      nextPrices[s.id] = priceInputs.value[s.id] ?? s.estimate
    }
    priceInputs.value = nextPrices
    if (market?.categories?.length) categories.value = market.categories
    orders.value = log || []
  } catch (e) {
    error.value = e.message || '坊市未开张'
  } finally {
    loading.value = false
  }
}

function switchCategory(key) {
  if (key === activeCategory.value) return
  activeCategory.value = key
  load(key)
}

async function buy(item) {
  if (buyingId.value || item.mine) return
  buyingId.value = item.id
  try {
    const res = await buyMarketItem(props.username, item.id)
    showToast(res?.message || `「${item.title}」已到手`)
    await load()
  } catch (e) {
    showToast(e.message || '交易失败')
  } finally {
    buyingId.value = 0
  }
}

async function sell(card) {
  if (sellingId.value) return
  sellingId.value = card.id
  try {
    const res = await sellMarketItem(props.username, card.id)
    showToast(res?.message || `「${card.name}」已卖出`)
    await load()
  } catch (e) {
    showToast(e.message || '牙人不收')
  } finally {
    sellingId.value = 0
  }
}

async function listStall(card) {
  if (listingId.value) return
  const price = Math.floor(Number(priceInputs.value[card.id]))
  if (!Number.isFinite(price) || price < 1) {
    showToast('请先填一个标价')
    return
  }
  listingId.value = card.id
  try {
    const res = await listMarketItem(props.username, card.id, price)
    showToast(res?.message || `「${card.name}」已摆上私摊`)
    delete priceInputs.value[card.id] // 藏品离袋，清掉旧输入
    await load()
  } catch (e) {
    showToast(e.message || '挂单失败')
  } finally {
    listingId.value = 0
  }
}

async function cancelStall(item) {
  if (cancelingId.value) return
  cancelingId.value = item.id
  try {
    const res = await cancelMarketItem(props.username, item.id)
    showToast(res?.message || `「${item.title}」已收回`)
    await load()
  } catch (e) {
    showToast(e.message || '撤单失败')
  } finally {
    cancelingId.value = 0
  }
}

onMounted(() => load())
</script>

<style scoped>
.page {
  position: relative;
  width: 100%;
  max-width: 1320px;
  margin: 0 auto;
  background: rgba(8, 5, 12, .22);
  border: 1px solid rgba(196, 154, 92, .18);
  border-radius: 22px;
  overflow: hidden;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .06),
    0 24px 60px rgba(0, 0, 0, .50),
    0 0 50px rgba(200, 16, 46, .12);
}

/* ===== 招牌 + 灵石池 ===== */
.hero {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 30px 26px 20px;
  border-bottom: 1px solid rgba(196, 154, 92, .16);
  background:
    radial-gradient(60% 120% at 50% -30%, rgba(200, 16, 46, .22), transparent 70%),
    rgba(10, 6, 14, .5);
}

.hero-core {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  min-width: 0;
}

.hero-seal {
  width: 54px;
  height: 54px;
  border-radius: 10px;
  display: grid;
  place-items: center;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 32px;
  font-weight: 700;
  color: #f7e9c4;
  background: linear-gradient(145deg, #6b0a16, #c8102e 70%, #8c0f1d);
  border: 2px solid var(--gold);
  box-shadow: 0 0 22px rgba(200, 16, 46, .55), inset 0 0 12px rgba(0, 0, 0, .45);
  transform: rotate(-6deg);
  flex-shrink: 0;
  animation: seal-pulse 3.6s ease-in-out infinite;
}

@keyframes seal-pulse {
  0%, 100% { box-shadow: 0 0 18px rgba(200, 16, 46, .45), inset 0 0 12px rgba(0, 0, 0, .45); }
  50% { box-shadow: 0 0 34px rgba(200, 16, 46, .75), inset 0 0 12px rgba(0, 0, 0, .45); }
}

.hero h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 28px;
  font-weight: 700;
  letter-spacing: 6px;
  color: #f3e8d6;
  text-shadow: 0 0 22px rgba(200, 16, 46, .6), 0 2px 4px rgba(0, 0, 0, .6);
  margin: 0;
  white-space: nowrap;
}

.hero-desc {
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(212, 175, 55, .75);
  margin: 6px 0 0;
}

.treasury {
  display: flex;
  align-items: baseline;
  gap: 8px;
  padding: 10px 18px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 12px;
  background:
    linear-gradient(135deg, rgba(140, 15, 29, .55), rgba(60, 8, 16, .8)),
    rgba(12, 8, 18, .8);
  box-shadow: 0 0 18px rgba(200, 16, 46, .35), inset 0 0 14px rgba(0, 0, 0, .4);
  flex-shrink: 0;
}

.treasury-label {
  font-size: 12px;
  letter-spacing: 2px;
  color: rgba(247, 233, 196, .85);
}

.treasury-num {
  font-size: 24px;
  font-weight: 700;
  color: #ffe9a8;
  letter-spacing: 1px;
  text-shadow: 0 0 14px rgba(212, 175, 55, .55);
}

.treasury-unit {
  font-size: 12px;
  color: rgba(232, 198, 106, .8);
}

.hero-side {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex-shrink: 0;
  opacity: .5;
}

.hero-rune {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 13px;
  letter-spacing: 2px;
  color: rgba(200, 16, 46, .75);
  text-shadow: 0 0 10px rgba(200, 16, 46, .5);
}

/* ===== 分类 + 货架 ===== */
.tabs-wrap { padding: 18px 22px 6px; }

.tabs {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 12px;
  border-bottom: 1px dashed rgba(196, 154, 92, .2);
}

.tab {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border-radius: 10px;
  border: 1px solid rgba(196, 154, 92, .28);
  background: rgba(12, 8, 18, .65);
  color: rgba(233, 221, 205, .78);
  font-family: inherit;
  font-size: 14px;
  letter-spacing: 2px;
  white-space: nowrap;
  cursor: pointer;
  transition: all .18s;
}

.tab:hover { color: var(--gold-soft); border-color: rgba(212, 175, 55, .5); }

.tab.active {
  color: #f7e9c4;
  background: linear-gradient(135deg, rgba(140, 15, 29, .78), rgba(200, 16, 46, .6));
  border-color: rgba(230, 180, 100, .65);
  box-shadow: 0 4px 16px rgba(200, 16, 46, .35), inset 0 0 10px rgba(0, 0, 0, .25);
}

.tab-icon { font-size: 15px; }

.tab-count {
  padding: 0 6px;
  border-radius: 99px;
  background: rgba(255, 233, 168, .16);
  color: #ffe9a8;
  font-size: 11px;
  line-height: 16px;
}

.goods-grid {
  list-style: none;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 14px;
  padding: 16px 0 6px;
}

.goods-card {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 14px 16px 12px;
  border-radius: 14px;
  border: 1px solid rgba(196, 154, 92, .26);
  background:
    radial-gradient(120% 90% at 90% -10%, rgba(200, 16, 46, .16), transparent 60%),
    rgba(16, 10, 22, .86);
  box-shadow: inset 0 0 20px rgba(0, 0, 0, .4);
  transition: transform .18s, border-color .18s, box-shadow .18s;
}

.goods-card:hover {
  transform: translateY(-3px);
  border-color: rgba(212, 175, 55, .55);
  box-shadow: 0 10px 26px rgba(0, 0, 0, .5), 0 0 22px rgba(200, 16, 46, .22);
}

/* 稀有度描边（魔宗四阶） */
.goods-card.g-uncommon { border-color: rgba(120, 200, 160, .42); }
.goods-card.g-rare { border-color: rgba(110, 160, 240, .45); }
.goods-card.g-epic { border-color: rgba(190, 130, 250, .5); }
.goods-card.g-legendary { border-color: rgba(255, 200, 90, .62); box-shadow: 0 0 20px rgba(255, 190, 80, .18), inset 0 0 20px rgba(0, 0, 0, .4); }

.goods-head {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.goods-icon {
  width: 42px;
  height: 42px;
  border-radius: 10px;
  display: grid;
  place-items: center;
  font-size: 22px;
  background: rgba(0, 0, 0, .38);
  border: 1px solid rgba(196, 154, 92, .32);
  flex-shrink: 0;
}

.goods-title-box { min-width: 0; }

.goods-title {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 1px;
  color: #f3e8d6;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.goods-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  margin-top: 5px;
}

.grade-badge {
  padding: 1px 7px;
  border-radius: 5px;
  font-size: 11px;
  color: #ffe9a8;
  background: rgba(212, 175, 55, .16);
  border: 1px solid rgba(212, 175, 55, .4);
}

.type-tag {
  padding: 1px 7px;
  border-radius: 5px;
  font-size: 11px;
  color: rgba(233, 221, 205, .82);
  background: rgba(255, 255, 255, .05);
  border: 1px solid rgba(255, 255, 255, .1);
}

.rarity-tag {
  padding: 1px 7px;
  border-radius: 5px;
  font-size: 11px;
  border: 1px solid transparent;
}

.rarity-tag.r-common { color: #b9b3c9; border-color: rgba(185, 179, 201, .3); }
.rarity-tag.r-uncommon { color: #8fe0bd; border-color: rgba(143, 224, 189, .35); }
.rarity-tag.r-rare { color: #8db6ff; border-color: rgba(141, 182, 255, .38); }
.rarity-tag.r-epic { color: #cf9cff; border-color: rgba(207, 156, 255, .4); }
.rarity-tag.r-legendary { color: #ffd27a; border-color: rgba(255, 210, 122, .5); }

.goods-desc {
  margin: 0;
  font-size: 12px;
  line-height: 1.7;
  color: rgba(233, 221, 205, .62);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 40px;
}

.goods-seller {
  margin: 0;
  font-size: 11px;
  letter-spacing: 1px;
  color: rgba(212, 175, 55, .62);
}

.private-tag {
  display: inline-block;
  padding: 0 5px;
  margin-right: 5px;
  border-radius: 4px;
  font-size: 10px;
  color: #a9e6c6;
  background: rgba(76, 195, 138, .14);
  border: 1px solid rgba(76, 195, 138, .4);
}

.buy-btn.self {
  background: rgba(255, 255, 255, .06);
  border-color: rgba(196, 154, 92, .3);
  color: rgba(233, 221, 205, .6);
}

/* ===== 我的摊位 ===== */
.my-stall-wrap { padding: 16px 22px 4px; }

.stall-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding-top: 10px;
}

.stall-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  border-radius: 10px;
  background: linear-gradient(90deg, rgba(140, 15, 29, .18), rgba(16, 10, 22, .8));
  border: 1px solid rgba(196, 154, 92, .28);
  font-size: 13px;
}

.stall-title {
  flex: 1;
  min-width: 0;
  color: #f3e8d6;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.stall-price {
  color: #ffe9a8;
  font-weight: 700;
  flex-shrink: 0;
}

.stall-price i { font-style: normal; font-size: 11px; margin-right: 3px; }

.stall-est {
  font-size: 11px;
  color: rgba(233, 221, 205, .42);
  flex-shrink: 0;
}

.cancel-btn {
  padding: 4px 12px;
  border-radius: 7px;
  border: 1px solid rgba(196, 154, 92, .4);
  background: rgba(12, 8, 18, .7);
  color: var(--gold-soft);
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  cursor: pointer;
  flex-shrink: 0;
}

.cancel-btn:hover:not(:disabled) { background: rgba(140, 15, 29, .45); color: #ffeccc; }
.cancel-btn:disabled { opacity: .5; cursor: wait; }

.goods-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-top: auto;
  padding-top: 8px;
  border-top: 1px dashed rgba(196, 154, 92, .18);
}

.goods-price {
  display: inline-flex;
  align-items: baseline;
  gap: 4px;
  font-size: 20px;
  font-weight: 700;
  color: #ffe9a8;
  text-shadow: 0 0 12px rgba(212, 175, 55, .4);
}

.goods-price i { font-style: normal; font-size: 13px; }

.buy-btn,
.sell-btn {
  padding: 7px 18px;
  border-radius: 9px;
  border: 1px solid rgba(230, 180, 100, .55);
  background: linear-gradient(135deg, #7a0f1d, #c8102e 75%);
  color: #ffeccc;
  font-family: inherit;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: filter .18s, transform .18s;
}

.buy-btn:hover:not(:disabled),
.sell-btn:hover:not(:disabled) { filter: brightness(1.14); transform: translateY(-1px); }

.buy-btn:disabled,
.sell-btn:disabled { opacity: .5; cursor: not-allowed; transform: none; }

/* ===== 寄售货栈（牙人回购 / 自行挂单） ===== */
.sell-wrap,
.log-wrap {
  padding: 16px 22px 8px;
}

.section-head {
  display: flex;
  align-items: baseline;
  gap: 12px;
  flex-wrap: wrap;
  padding-bottom: 8px;
  border-bottom: 1px dashed rgba(196, 154, 92, .2);
}

.section-head h2 {
  margin: 0;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 19px;
  letter-spacing: 4px;
  color: #f3e8d6;
}

.section-sub {
  margin: 0;
  font-size: 12px;
  color: rgba(233, 221, 205, .5);
  letter-spacing: 1px;
}

.sell-list {
  list-style: none;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 10px;
  padding-top: 12px;
}

.sell-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid rgba(196, 154, 92, .22);
  background: rgba(16, 10, 22, .8);
}

.sell-card.g-uncommon { border-color: rgba(120, 200, 160, .35); }
.sell-card.g-rare { border-color: rgba(110, 160, 240, .38); }
.sell-card.g-epic { border-color: rgba(190, 130, 250, .42); }
.sell-card.g-legendary { border-color: rgba(255, 200, 90, .55); }

.sell-icon { font-size: 22px; flex-shrink: 0; }
.sell-body { flex: 1; min-width: 0; }

.sell-body h4 {
  margin: 0;
  font-size: 14px;
  color: #f3e8d6;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sell-tags { display: flex; gap: 5px; margin-top: 4px; }

.sell-act {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 5px;
  flex-shrink: 0;
}

.sell-price {
  font-size: 14px;
  font-weight: 700;
  color: #ffe9a8;
}

.sell-price i { font-style: normal; font-size: 11px; margin-right: 3px; }

.sell-btn {
  padding: 4px 12px;
  font-size: 12px;
  letter-spacing: 1px;
  background: linear-gradient(135deg, #3c2a10, #6b4c12 75%);
  border-color: rgba(212, 175, 55, .45);
  color: #ffe9a8;
}

.stall-form {
  display: flex;
  align-items: center;
  gap: 5px;
}

.price-input {
  width: 84px;
  padding: 4px 6px;
  border-radius: 7px;
  border: 1px solid rgba(196, 154, 92, .4);
  background: rgba(8, 5, 12, .85);
  color: #ffe9a8;
  font-family: inherit;
  font-size: 12px;
  text-align: right;
  outline: none;
}

.price-input:focus { border-color: var(--gold); box-shadow: 0 0 8px rgba(212, 175, 55, .3); }

.list-btn {
  padding: 4px 10px;
  border-radius: 7px;
  border: 1px solid rgba(76, 195, 138, .45);
  background: linear-gradient(135deg, #12402f, #1d6b4b 75%);
  color: #c8f6df;
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  cursor: pointer;
}

.list-btn:hover:not(:disabled) { filter: brightness(1.18); }
.list-btn:disabled { opacity: .5; cursor: wait; }

/* ===== 交易手札 ===== */
.log-list {
  list-style: none;
  padding-top: 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  max-height: 260px;
  overflow-y: auto;
}

.log-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-radius: 9px;
  background: rgba(16, 10, 22, .62);
  border: 1px solid rgba(196, 154, 92, .12);
  font-size: 13px;
}

.log-tag {
  padding: 1px 8px;
  border-radius: 5px;
  font-size: 11px;
  letter-spacing: 1px;
  flex-shrink: 0;
}

.tag-buy { color: #ffb3b3; background: rgba(200, 16, 46, .22); border: 1px solid rgba(200, 16, 46, .4); }
.tag-sell { color: #a9e6c6; background: rgba(76, 195, 138, .14); border: 1px solid rgba(76, 195, 138, .35); }

.log-title {
  flex: 1;
  min-width: 0;
  color: #e9ddcd;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.log-who {
  font-size: 11px;
  color: rgba(233, 221, 205, .45);
  flex-shrink: 0;
}

.log-price { font-weight: 700; flex-shrink: 0; }
.log-price.minus { color: #ff9aa6; }
.log-price.plus { color: #8fe0bd; }

.empty {
  padding: 26px 0;
  text-align: center;
  font-size: 14px;
  letter-spacing: 2px;
  color: rgba(233, 221, 205, .5);
}

.empty.small { padding: 18px 0; font-size: 13px; }

.goto {
  color: var(--gold-soft);
  cursor: pointer;
  text-decoration: underline dotted;
}

.goto:hover { color: #ffe9a8; }

.page-foot {
  margin-top: 14px;
  padding: 14px 0 18px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 2px;
  color: rgba(233, 221, 205, .32);
  border-top: 1px solid rgba(196, 154, 92, .12);
}

@media (max-width: 780px) {
  .hero { padding: 20px 16px 14px; }
  .hero-side { display: none; }
  .hero-core { flex-wrap: wrap; gap: 10px; }
  .hero h1 { font-size: 22px; letter-spacing: 4px; }
  .hero-seal { width: 44px; height: 44px; font-size: 26px; }
  .tabs-wrap, .sell-wrap, .log-wrap { padding-left: 14px; padding-right: 14px; }
  .goods-grid { grid-template-columns: 1fr; }
  .sell-list { grid-template-columns: 1fr; }
  .log-who { display: none; }
}
</style>
