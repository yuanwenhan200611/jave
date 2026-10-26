/**
 * 首页接口封装 —— 对接 Spring Boot 后端 /api/home/**
 * 后端地址通过 vite 代理（/api -> http://localhost:8081）
 */

async function request(url, { method = 'GET' } = {}) {
  let res
  try {
    res = await fetch(url, { method })
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

/** 首页展示：分类树 + 热门条目 */
export function fetchHomeSummary() {
  return request('/api/home/summary')
}

/** 分类树（分级分类） */
export function fetchCategoryTree() {
  return request('/api/home/categories')
}

/**
 * 搜索
 * @param {string} keyword 关键词
 * @param {number|string} [categoryId] 分类 id，可选；传任意层级分类会包含其全部子孙分类
 */
export function searchItems(keyword, categoryId) {
  const params = new URLSearchParams()
  if (keyword) params.set('keyword', keyword)
  if (categoryId) params.set('categoryId', categoryId)
  const qs = params.toString()
  return request(`/api/home/search${qs ? `?${qs}` : ''}`)
}
