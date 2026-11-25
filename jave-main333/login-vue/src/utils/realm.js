/**
 * 境界唯一口径（与后端 com.fenglin.springboottest.util.RealmTier 一致）
 *
 * 弟子境：炼气 / 筑基 / 金丹
 * 真传境：元婴 / 化神
 * 长老境：炼虚 / 合体 / 大乘 / 渡劫
 * 至尊境：魔尊
 *
 * 分榜：长老境 + 至尊境 → 长老榜；弟子境 + 真传境 → 弟子榜。
 * 每个大境界再分小层次，玩家按修为在区间内折算。
 */

export const REALMS = ['炼气', '筑基', '金丹', '元婴', '化神', '炼虚', '合体', '大乘', '渡劫', '魔尊']

/** 各境界修为门槛（下标对应 REALMS） */
export const REALM_THRESHOLD = [0, 1000, 5000, 15000, 40000, 100000, 250000, 600000, 1500000, 5000000]

/** 每个大境界的小层次，由低到高 */
export const STAGES = {
  炼气: ['一层', '二层', '三层', '四层', '五层', '六层', '七层', '八层', '九层'],
  筑基: ['初期', '中期', '后期', '巅峰'],
  金丹: ['初期', '中期', '后期', '巅峰'],
  元婴: ['初期', '中期', '后期', '巅峰'],
  化神: ['初期', '中期', '后期', '巅峰'],
  炼虚: ['小成', '大成', '圆满', '巅峰'],
  合体: ['初期', '中期', '后期', '巅峰'],
  大乘: ['初期', '中期', '后期', '巅峰'],
  渡劫: ['一劫', '三劫', '五劫', '七劫', '九劫'],
  魔尊: ['一重', '三重', '五重', '七重', '九重']
}

export const ELDER_MIN_REALM = '炼虚'

export const TIERS = {
  disciple: { label: '弟子境', realms: ['炼气', '筑基', '金丹'], elder: false },
  trueDisciple: { label: '真传境', realms: ['元婴', '化神'], elder: false },
  elder: { label: '长老境', realms: ['炼虚', '合体', '大乘', '渡劫'], elder: true },
  supreme: { label: '至尊境', realms: ['魔尊'], elder: true }
}

const REALM_TIER = Object.entries(TIERS).reduce((acc, [key, tier]) => {
  tier.realms.forEach(r => { acc[r] = key })
  return acc
}, {})

/** 境界 → 辈分层 key */
export function tierOf(realm) {
  return REALM_TIER[realm] || 'disciple'
}

/** 境界 → 辈分层标签 */
export function tierLabel(realm) {
  return TIERS[tierOf(realm)].label
}

/** 是否属于长老榜 */
export function isElder(realm) {
  return TIERS[tierOf(realm)].elder
}

/** 某境界的小层次列表 */
export function stagesOf(realm) {
  return STAGES[realm] || []
}

/** 按修为折算小层次（末境界按每 100 万一重，九重封顶） */
export function stageOf(realm, cultivation) {
  const list = stagesOf(realm)
  if (!list.length) return ''
  const idx = REALMS.indexOf(realm)
  const lo = REALM_THRESHOLD[idx] || 0
  const hi = idx + 1 < REALM_THRESHOLD.length ? REALM_THRESHOLD[idx + 1] : -1
  let seg
  if (hi < 0) seg = Math.floor((cultivation - lo) / 1000000)
  else seg = Math.floor(((cultivation - lo) * list.length) / Math.max(1, hi - lo))
  seg = Math.max(0, Math.min(list.length - 1, seg))
  return list[seg]
}

/** 完整境界：境界 + 层次，如「炼气七层」「魔尊九重」 */
export function fullRealm(realm, stage) {
  const r = realm || '炼气'
  return stage ? r + stage : r
}

/**「境界+层次」可比权重：大境界序号×100 + 层次序号（纯大境界按第 0 层，兼容旧数据） */
export function realmWeight(realmWithStage) {
  if (!realmWithStage) return 0
  const s = String(realmWithStage).trim()
  const realm = REALMS.find(r => s.startsWith(r))
  if (!realm) return 0
  const suffix = s.slice(realm.length).trim()
  const list = STAGES[realm] || []
  const stageIdx = suffix ? Math.max(0, list.indexOf(suffix)) : 0
  return REALMS.indexOf(realm) * 100 + stageIdx
}

/** 所有可选门槛：大境界 + 各层次，按境界分组用 */
export const REALM_OPTIONS = REALMS.map(realm => ({
  realm,
  stages: [''].concat(STAGES[realm] || [])
}))

/** 境界配色：越高越红（榜单 / 洞府 / 魔功殿共用） */
export function realmClass(realm) {
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
