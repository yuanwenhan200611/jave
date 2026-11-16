/**
 * 任务阁接口封装 —— 对接 Spring Boot 后端 /api/quest/**
 * 后端地址通过 vite 代理（/api -> http://localhost:8081）
 *
 * 悬赏分两类：
 *   · sect     宗门颁发，奖励贡献值 / 灵石（可兼得）
 *   · personal 个人发布，奖励天才地宝 / 法宝等（reward_item）
 * 接取门槛：修为（min_realm）+ 名额（max_accept）
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

/** 悬赏来源统计（宗门 / 个人数量） */
export function fetchQuestTypes() {
  return request('/api/quest/types')
}

/** 分类统计（分堂 tab 计数，可按 type 过滤） */
export function fetchQuestSummary(type) {
  const qs = type ? `?type=${encodeURIComponent(type)}` : ''
  return request(`/api/quest/summary${qs}`)
}

/**
 * 任务牌分页列表
 * @param {object} opts
 * @param {'sect'|'personal'} [opts.type] 悬赏来源（空 = 全部）
 * @param {string} [opts.category] 分类（空 = 全部）
 * @param {'hot'|'new'|'reward'|'hard'} [opts.sort] 排序：最热/最新/奖励/难度
 * @param {number} [opts.page] 页码，从 1 开始
 * @param {number} [opts.size] 每页条数
 * @returns {Promise<{list:Array, total:number, page:number, size:number, pages:number}>}
 */
export function fetchQuestList({ type, category, sort, page = 1, size = 10 } = {}) {
  const params = new URLSearchParams()
  if (type) params.set('type', type)
  if (category) params.set('category', category)
  if (sort) params.set('sort', sort)
  params.set('page', page)
  params.set('size', size)
  return request(`/api/quest/list?${params.toString()}`)
}

/**
 * 发布个人悬赏（奖励为物品：天才地宝/法宝等）
 * @param {object} data { username, title, description, category, difficulty, minRealm, maxAccept, rewardItem, icon }
 */
export function publishQuest(data) {
  return request('/api/quest/publish', { method: 'POST', body: data })
}

/** 接取任务（后端校验修为门槛与名额） */
export function acceptQuest(username, questId) {
  return request('/api/quest/accept', { method: 'POST', body: { username, questId } })
}

/** 完成任务（结算贡献值/灵石/物品，洞府联动） */
export function finishQuest(username, questId) {
  return request('/api/quest/finish', { method: 'POST', body: { username, questId } })
}

/** 放弃任务（释放名额） */
export function abandonQuest(username, questId) {
  return request('/api/quest/abandon', { method: 'POST', body: { username, questId } })
}

/** 我的任务牌（洞府「我的任务」联动） */
export function fetchMyQuests(username) {
  return request(`/api/quest/my?username=${encodeURIComponent(username)}`)
}

/** 洞府档案（取当前境界，判断能否接取） */
export function fetchProfileRealm(username) {
  return request(`/api/profile?username=${encodeURIComponent(username)}`)
}
