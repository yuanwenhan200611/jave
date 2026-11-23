/**
 * 坊市·交易市场接口封装 —— 对接 Spring Boot 后端 /api/market/**
 *
 * 灵石经济第三极（与任务阁 / 魔功殿共用同一本灵石账）：
 *   任务阁交差赚灵石 → 魔功殿花灵石换修为 / 坊市花灵石买货
 *   储物空间的法宝 / 残篇 / 神通可卖给坊市牙人换回灵石（回购即离手）
 */

async function request(url, { method = 'GET', body } = {}) {
  let res
  try {
    res = await fetch(url, {
      method,
      headers: body ? { 'Content-Type': 'application/json' } : undefined,
      body: body ? JSON.stringify(body) : undefined
    })
  } catch {
    throw new Error('网络异常，请确认后端服务已启动')
  }
  if (!res.ok) {
    throw new Error(`服务器错误（${res.status}）`)
  }
  const json = await res.json()
  if (json.code !== 200) {
    throw new Error(json.msg || '请求失败')
  }
  return json.data
}

/**
 * 坊市货架
 * @returns {Promise<{stonesAvailable:number, items:Array, categories:Array, sellable:Array}>}
 */
export function fetchMarketList(username, category = 'all') {
  const q = new URLSearchParams({ username, category: category || 'all' })
  return request(`/api/market/list?${q.toString()}`)
}

/** 我的交易手札（买入 / 卖出流水） */
export function fetchMarketOrders(username, limit = 20) {
  const q = new URLSearchParams({ username, limit: String(limit) })
  return request(`/api/market/orders?${q.toString()}`)
}

/** 买货：扣灵石，货入储物空间 / 功法收录 / 丹药当场服用 */
export function buyMarketItem(username, itemId) {
  return request('/api/market/buy', { method: 'POST', body: { username, itemId } })
}

/** 寄售回购：把储物空间的藏品卖给坊市牙人换灵石 */
export function sellMarketItem(username, rewardId) {
  return request('/api/market/sell', { method: 'POST', body: { username, rewardId } })
}

/** 自行挂单：给藏品自由标价，摆上私摊（标价需在牙人估价 0.5~3 倍之间） */
export function listMarketItem(username, rewardId, price) {
  return request('/api/market/list-item', { method: 'POST', body: { username, rewardId, price } })
}

/** 撤单：把未售出的私摊货收回储物空间 */
export function cancelMarketItem(username, itemId) {
  return request('/api/market/cancel', { method: 'POST', body: { username, itemId } })
}
