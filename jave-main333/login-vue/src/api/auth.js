/**
 * 认证接口封装 —— 对接 Spring Boot 后端
 * 后端地址通过 vite 代理（/api -> http://localhost:8081），生产部署时改为网关/Nginx 即可
 */

/**
 * 请求工具：统一处理 JSON 与后端 Result 结构 { code, msg, data }
 * code === 200 视为成功，否则抛出携带 msg 的异常
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

/** 获取图形验证码：返回 { captchaId, image(base64) } */
export function getCaptcha() {
  return request('/api/captcha')
}

/** 注册：{ username, password, captchaId, captcha } */
export function register({ username, password, captchaId, captcha }) {
  return request('/api/register', {
    method: 'POST',
    body: { username, password, captchaId, captcha }
  })
}

/** 登录：{ username, password, remember }，成功返回 { token, username } */
export function login({ username, password, remember }) {
  return request('/api/login', {
    method: 'POST',
    body: { username, password, remember }
  })
}
