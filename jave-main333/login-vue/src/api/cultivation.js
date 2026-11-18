/**
 * 魔功殿（增修为）接口封装 —— 对接 Spring Boot 后端 /api/cultivation/**
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

/** 魔功殿总览：修为进度 / 灵石贡献余额 / 法门冷却 / 最近修炼记录 */
export function fetchCultivationInfo(username) {
  return request(`/api/cultivation/info?username=${encodeURIComponent(username)}`)
}

/** 修炼一门魔功：{ key } 掷结果（大成/小成/反噬），自动判定境界突破 */
export function practice(methodKey, username) {
  return request('/api/cultivation/practice', {
    method: 'POST',
    body: { username, key: methodKey }
  })
}
