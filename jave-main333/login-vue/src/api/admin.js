/**
 * 后台管理接口封装 —— 对接 Spring Boot /api/admin/**
 * 后台 token 单独存 localStorage，不与前台会员 token 混用。
 */

const TOKEN_KEY = 'jiyou_admin_token'

export function getAdminToken() {
  return localStorage.getItem(TOKEN_KEY) || ''
}

export function setAdminToken(token) {
  if (token) localStorage.setItem(TOKEN_KEY, token)
  else localStorage.removeItem(TOKEN_KEY)
}

async function request(url, { method = 'GET', body, auth = true } = {}) {
  const headers = {}
  if (body) headers['Content-Type'] = 'application/json'
  const token = getAdminToken()
  if (auth && token) headers['X-Admin-Token'] = token

  let res
  try {
    res = await fetch(url, { method, headers, body: body ? JSON.stringify(body) : undefined })
  } catch {
    throw new Error('网络异常，请确认后端服务已启动')
  }

  if (!res.ok) {
    throw new Error(`服务器错误（${res.status}）`)
  }

  const json = await res.json()
  if (json.code !== 200) {
    // 后台会话失效：清掉本地 token，下次进登录页就是干净状态
    if (json.code === 401) setAdminToken('')
    throw new Error(json.msg || '请求失败')
  }
  return json.data
}

/** 后台登录（没有注册接口） */
export function adminLogin(username, password) {
  return request('/api/admin/login', {
    method: 'POST',
    body: { username, password },
    auth: false
  })
}

export function adminLogout() {
  return request('/api/admin/logout', { method: 'POST' }).finally(() => setAdminToken(''))
}

export function fetchAdminSession() {
  return request('/api/admin/session')
}

/** 洞府档案列表 + 概览 */
export function fetchAdminProfiles({ keyword = '', page = 1, size = 10 } = {}) {
  const params = new URLSearchParams({ keyword, page: String(page), size: String(size) })
  return request(`/api/admin/profiles?${params}`)
}

export function createAdminProfile(data) {
  return request('/api/admin/profiles', { method: 'POST', body: data })
}

export function updateAdminProfile(username, data) {
  return request(`/api/admin/profiles/${encodeURIComponent(username)}`, {
    method: 'PUT',
    body: data
  })
}

export function deleteAdminProfile(username) {
  return request(`/api/admin/profiles/${encodeURIComponent(username)}`, { method: 'DELETE' })
}
