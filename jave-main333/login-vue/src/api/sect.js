/**
 * 宗门模块接口封装 —— 对接 Spring Boot 后端 /api/sect/**
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
 * 宗门榜：NPC 弟子 + 当前玩家（传 username 时并入排行）
 * @param {string} [username] 当前登录名，不传则只有 NPC
 * @param {'power'|'contribution'} [sortBy] 榜单维度，默认战力
 * @param {'all'|'elder'|'disciple'} [tier] 辈分榜，默认全宗
 */
export function fetchRank(username, sortBy = 'power', tier = 'all') {
  const params = new URLSearchParams({ sortBy, tier })
  if (username) params.set('username', username)
  return request(`/api/sect/rank?${params}`)
}

/** 各堂口人数统计（与当前榜单同范围） */
export function fetchHallStats(username, tier = 'all') {
  const params = new URLSearchParams({ tier })
  if (username) params.set('username', username)
  return request(`/api/sect/halls?${params}`)
}

/* 注：旧的免费探索接口 fetchExplore（/api/sect/explore）已随免费秘境探索一并下线，
   探索秘境统一走 api/secret.js 的 roamSecret（天机引路费 200，每次必收）。 */
