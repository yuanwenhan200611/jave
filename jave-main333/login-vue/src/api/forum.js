/**
 * 血辩台（原论道）接口封装 —— 对接 Spring Boot 后端 /api/forum/**
 * 论道即修炼：开坛讲道 / 香火供奉 / 驳道全部真实结算修为与灵石贡献。
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
 * 帖子分页列表
 * @param {'new'|'hot'} [sort] new 按时间 / hot 按香火数
 * @param {string} [username] 当前用户，返回 incensedIds / counteredIds 供按钮禁用
 */
export function fetchPosts({ sort = 'new', page = 1, size = 10, username } = {}) {
  const qs = new URLSearchParams({ sort, page, size })
  if (username) qs.set('username', username)
  return request(`/api/forum/posts?${qs.toString()}`)
}

/**
 * 开坛讲道（发帖即修炼）
 * 花费 20 灵石设坛，讲道得修为 +60~150，60s 调息
 * 返回 { post, delta, story, cultivation, realm, breakthrough, ... }
 */
export function createPost({ author, title, content }) {
  return request('/api/forum/posts', {
    method: 'POST',
    body: { author, title, content }
  })
}

/**
 * 香火供奉（每人每帖一次）
 * 花 10 灵石听道：自己 +15~40 修为，帖主 +5 贡献分成
 */
export function incensePost(id, username) {
  return request(`/api/forum/posts/${id}/incense`, {
    method: 'POST',
    body: { username }
  })
}

/**
 * 驳道（每人每帖一次）
 * 押 50 修为上台论剑：45% 胜 +120~300 / 败 -50
 */
export function counterPost(id, username) {
  return request(`/api/forum/posts/${id}/counter`, {
    method: 'POST',
    body: { username }
  })
}
