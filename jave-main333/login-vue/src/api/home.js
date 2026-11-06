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

/** 首页展示：分类树 + 热门榜 + 最新 + 分类计数 + 品阶 */
export function fetchHomeSummary() {
  return request('/api/home/summary')
}

/** 分类树（分级分类） */
export function fetchCategoryTree() {
  return request('/api/home/categories')
}

/**
 * 搜索（分页）
 * @param {object} opts
 * @param {string} [opts.keyword] 关键词
 * @param {number|string} [opts.categoryId] 分类 id，传任意层级会包含其全部子孙分类
 * @param {'hot'|'new'|'grade'|'title'} [opts.sort] 排序方式
 * @param {number} [opts.page] 页码，从 1 开始
 * @param {number} [opts.size] 每页条数
 * @returns {Promise<{list:Array, total:number, page:number, size:number, pages:number}>}
 */
export function searchItems({ keyword, categoryId, sort, page = 1, size = 10 } = {}) {
  const params = new URLSearchParams()
  if (keyword) params.set('keyword', keyword)
  if (categoryId) params.set('categoryId', categoryId)
  if (sort) params.set('sort', sort)
  params.set('page', page)
  params.set('size', size)
  return request(`/api/home/search?${params.toString()}`)
}

/** 搜索热词 */
export function fetchHotKeywords(limit = 10, days = 30) {
  return request(`/api/home/hot-keywords?limit=${limit}&days=${days}`)
}

/** 条目详情（后端会同时把浏览量 +1） */
export function fetchItemDetail(id) {
  return request(`/api/home/item/${id}`)
}

/** 同分类相关推荐 */
export function fetchRelatedItems(id, limit = 4) {
  return request(`/api/home/item/${id}/related?limit=${limit}`)
}

/** 浏览量 +1 */
export function increaseItemView(id) {
  return request(`/api/home/item/${id}/view`, { method: 'POST' })
}
