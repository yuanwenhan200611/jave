/**
 * 论道模块接口封装 —— 对接 Spring Boot 后端 /api/forum/**
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
 * @param {'new'|'hot'} [sort] new 按时间 / hot 按点赞
 */
export function fetchPosts({ sort = 'new', page = 1, size = 10 } = {}) {
  return request(`/api/forum/posts?sort=${sort}&page=${page}&size=${size}`)
}

/** 发帖 */
export function createPost({ author, title, content }) {
  return request('/api/forum/posts', {
    method: 'POST',
    body: { author, title, content }
  })
}

/** 道心相印（点赞 +1），返回 { likes: n } */
export function likePost(id) {
  return request(`/api/forum/posts/${id}/like`, { method: 'POST' })
}
