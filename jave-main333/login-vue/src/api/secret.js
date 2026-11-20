/**
 * 秘境接口封装 —— 对接 Spring Boot 后端 /api/secret/**
 *
 * 贡献值经济闭环（与功法阁共用同一本账）：
 *   任务阁交差赚贡献值 → 功法阁参悟 / 秘境破界花贡献值
 *   破界进入按秘境品阶收门票；随机探秘收固定「天机引路费」20
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
 * 秘境状态总览
 * @returns {Promise<{contributionTotal:number, skillSpent:number, secretSpent:number,
 *                    contributionAvailable:number, secretCount:number, enteredIds:number[],
 *                    entered:Array}>}
 */
export function fetchSecretStatus(username) {
  return request(`/api/secret/status?username=${encodeURIComponent(username)}`)
}

/** 破界进入指定秘境（后端校验贡献值余额与重复进入） */
export function enterSecret(username, itemId) {
  return request('/api/secret/enter', { method: 'POST', body: { username, itemId } })
}

/** 随机探秘（天机引路费 20 贡献值，后端校验余额） */
export function roamSecret(username) {
  return request('/api/secret/roam', { method: 'POST', body: { username } })
}

/** 我的已开辟秘境（洞府「已辟秘境」联动） */
export function fetchMySecrets(username) {
  return request(`/api/secret/mine?username=${encodeURIComponent(username)}`)
}

/** 储物空间（洞府联动）：历次探索获得的法宝 / 残篇 / 神通 */
export function fetchSecretStorage(username) {
  return request(`/api/secret/storage?username=${encodeURIComponent(username)}`)
}
