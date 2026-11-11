/**
 * 洞府（个人页）接口封装 —— 对接 Spring Boot 后端 /api/profile/**
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
 * 读取个人档案 + 跨模块统计
 * @returns {Promise<{profile:object, user:{username,createdAt}, stats:{postCount,likeCount,searchCount}}>}
 */
export function fetchProfile(username) {
  return request(`/api/profile?username=${encodeURIComponent(username)}`)
}

/**
 * 保存个人档案（道号 / 头像 / 境界 / 堂口 / 签名）
 * @param {{username:string, nickname?:string, icon?:string, realm?:string, hall?:string, bio?:string}} data
 */
export function saveProfile(data) {
  return request('/api/profile/update', { method: 'POST', body: data })
}

/** 我的帖子（论道联动） */
export function fetchMyPosts(username) {
  return request(`/api/profile/posts?username=${encodeURIComponent(username)}`)
}

/** 搜索足迹（首页联动） */
export function fetchMySearches(username) {
  return request(`/api/profile/searches?username=${encodeURIComponent(username)}`)
}
