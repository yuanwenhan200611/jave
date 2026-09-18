# login-vue

由 `login.html` 改造的 Vue 3 + Vite 登录页面，视觉与交互与原页面保持一致。

## 运行

```bash
npm install
npm run dev      # 开发预览 http://127.0.0.1:5173
npm run build    # 打包到 dist/
npm run preview  # 预览打包结果
```

打包使用 `vite-plugin-singlefile`，产物是**单个 `dist/index.html`**（JS 与 CSS 全部内联），
双击就能用浏览器直接打开，不需要起服务器，也方便直接丢到任意静态托管上。

## 目录结构

```
login-vue/
├── index.html
├── package.json
├── vite.config.js
└── src/
    ├── main.js                   # 应用入口
    ├── App.vue                   # 页面骨架（左右分栏布局）
    ├── styles/global.css         # 全局变量与重置样式
    ├── api/auth.js               # 登录接口封装（当前为模拟实现）
    ├── composables/useToast.js   # 全局 Toast 状态（模块级单例）
    └── components/
        ├── BrandPanel.vue        # 左侧品牌区
        ├── LoginForm.vue         # 右侧登录表单（校验、显隐密码、提交）
        ├── SocialLogin.vue       # 第三方登录按钮
        └── ToastMessage.vue      # 轻提示组件
```

## 接入真实接口

修改 `src/api/auth.js` 中 `login()` 的实现即可，组件层无需改动：

```js
return fetch('/api/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username, password, remember })
}).then(res => {
  if (!res.ok) throw new Error('登录失败')
  return res.json()
})
```

登录成功后的跳转 / 存 token 逻辑写在 `src/App.vue` 的 `handleSuccess` 中。

## 校验规则

- 用户名 / 邮箱：不能为空
- 密码：不少于 6 位
