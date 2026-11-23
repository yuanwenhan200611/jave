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

/** 宗门榜（战力降序） */
export function fetchRank() {
  return request('/api/sect/rank')
}

/** 各堂口人数统计 */
export function fetchHallStats() {
  return request('/api/sect/halls')
}

/* 注：旧的免费探索接口 fetchExplore（/api/sect/explore）已随免费秘境探索一并下线，
   探索秘境统一走 api/secret.js 的 roamSecret（天机引路费 200，每次必收）。 */
