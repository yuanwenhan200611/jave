/**
 * 登录接口封装
 * 当前为模拟实现，接入真实后端时替换函数内部即可，调用方无需改动。
 */
export function login({ username, password, remember }) {
  // 真实接口示例：
  // return fetch('/api/login', {
  //   method: 'POST',
  //   headers: { 'Content-Type': 'application/json' },
  //   body: JSON.stringify({ username, password, remember })
  // }).then(res => {
  //   if (!res.ok) throw new Error('登录失败')
  //   return res.json()
  // })

  return new Promise(resolve => {
    setTimeout(() => {
      resolve({
        token: 'mock-token-' + Date.now(),
        username,
        remember
      })
    }, 900)
  })
}
