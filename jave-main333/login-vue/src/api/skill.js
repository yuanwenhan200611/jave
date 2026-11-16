/**
 * 功法阁接口封装 —— 对接 Spring Boot 后端 /api/skill/**
 * 后端地址通过 vite 代理（/api -> http://localhost:8081）
 *
 * 贡献值经济闭环：
 *   任务阁交差赚贡献值 → 功法阁参悟花贡献值（费用按品阶：天阶>地阶>玄阶>黄阶）
 *   可用贡献值 = 累计所得 - 参悟所耗
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
 * 参悟状态总览
 * @returns {Promise<{contributionTotal:number, skillSpent:number, contributionAvailable:number,
 *                    skillCount:number, learnedIds:number[], learned:Array}>}
 */
export function fetchSkillStatus(username) {
  return request(`/api/skill/status?username=${encodeURIComponent(username)}`)
}

/** 参悟功法（后端校验贡献值余额与重复参悟） */
export function learnSkill(username, itemId) {
  return request('/api/skill/learn', { method: 'POST', body: { username, itemId } })
}

/** 我的已参悟功法（洞府「已习功法」联动） */
export function fetchMySkills(username) {
  return request(`/api/skill/mine?username=${encodeURIComponent(username)}`)
}
