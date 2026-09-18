<template>
  <main class="form-side">
    <div class="form-head">
      <h2>账号登录</h2>
      <p>请输入你的账号信息以继续</p>
    </div>

    <form novalidate @submit.prevent="handleSubmit">
      <div class="field" :class="{ error: errors.username }">
        <label for="username">用户名 / 邮箱</label>
        <div class="input-box">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>
          <input
            id="username"
            v-model.trim="form.username"
            type="text"
            placeholder="请输入用户名或邮箱"
            autocomplete="username"
            @input="errors.username = false"
          >
        </div>
        <div class="err-tip">请输入用户名或邮箱</div>
      </div>

      <div class="field" :class="{ error: errors.password }">
        <label for="password">密码</label>
        <div class="input-box">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
          <input
            id="password"
            v-model="form.password"
            :type="showPassword ? 'text' : 'password'"
            placeholder="请输入密码"
            autocomplete="current-password"
            @input="errors.password = false"
          >
          <button type="button" class="toggle-eye" :aria-label="showPassword ? '隐藏密码' : '显示密码'" @click="showPassword = !showPassword">
            <svg v-if="!showPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
              <circle cx="12" cy="12" r="3" />
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
              <line x1="1" y1="1" x2="23" y2="23" />
            </svg>
          </button>
        </div>
        <div class="err-tip">密码不能少于 6 位</div>
      </div>

      <div class="row-between">
        <label class="remember">
          <input id="remember" v-model="form.remember" type="checkbox"> 记住我
        </label>
        <a href="#" class="forgot" @click.prevent="emit('forgot')">忘记密码？</a>
      </div>

      <button type="submit" class="btn" :class="{ loading }" :disabled="loading">
        {{ loading ? '登录中…' : '登 录' }}
      </button>
    </form>

    <SocialLogin @select="handleSocial" />

    <p class="signup">还没有账号？<a href="#" @click.prevent="emit('signup')">立即注册</a></p>
  </main>
</template>

<script setup>
import { reactive, ref } from 'vue'
import SocialLogin from './SocialLogin.vue'
import { useToast } from '../composables/useToast'
import { login } from '../api/auth'

const emit = defineEmits(['success', 'forgot', 'signup'])

const { showToast } = useToast()

const form = reactive({
  username: '',
  password: '',
  remember: false
})

const errors = reactive({
  username: false,
  password: false
})

const showPassword = ref(false)
const loading = ref(false)

function validate() {
  errors.username = !form.username
  errors.password = form.password.length < 6
  return !errors.username && !errors.password
}

async function handleSubmit() {
  if (!validate()) return

  loading.value = true
  try {
    const res = await login({
      username: form.username,
      password: form.password,
      remember: form.remember
    })
    showToast(`登录成功，欢迎回来 ${res.username}`)
    emit('success', res)
  } catch (err) {
    showToast(err.message || '登录失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

const socialName = { wechat: '微信', wecom: '企业微信' }
function handleSocial(type) {
  showToast(`${socialName[type]}登录（演示）`)
}
</script>

<style scoped>
.form-side {
  padding: 56px 52px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.form-head h2 {
  font-size: 24px;
  font-weight: 700;
}

.form-head p {
  margin-top: 8px;
  font-size: 13px;
  color: var(--text-soft);
}

form {
  margin-top: 30px;
}

.field {
  margin-bottom: 18px;
}

.field label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  margin-bottom: 8px;
  color: #374151;
}

.input-box {
  position: relative;
}

.input-box > svg {
  position: absolute;
  left: 13px;
  top: 50%;
  transform: translateY(-50%);
  width: 18px;
  height: 18px;
  color: #9ca3af;
  pointer-events: none;
}

.input-box input {
  width: 100%;
  height: 46px;
  padding: 0 44px 0 42px;
  border: 1px solid var(--border);
  border-radius: 10px;
  font-size: 14px;
  font-family: inherit;
  color: var(--text);
  background: #fbfbfd;
  transition: border-color .18s, box-shadow .18s, background .18s;
  outline: none;
}

.input-box input::placeholder {
  color: #b3b9c4;
}

.input-box input:focus {
  border-color: var(--primary-light);
  background: #fff;
  box-shadow: 0 0 0 4px rgba(99, 102, 241, .14);
}

.field.error .input-box input {
  border-color: var(--danger);
  background: #fff5f7;
}

.toggle-eye {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  width: 32px;
  height: 32px;
  border: 0;
  background: none;
  cursor: pointer;
  color: #9ca3af;
  display: grid;
  place-items: center;
  border-radius: 8px;
}

.toggle-eye:hover {
  color: var(--primary);
  background: #f0f1ff;
}

.toggle-eye svg {
  width: 17px;
  height: 17px;
}

.err-tip {
  display: none;
  margin-top: 6px;
  font-size: 12px;
  color: var(--danger);
}

.field.error .err-tip {
  display: block;
}

.row-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin: 4px 0 22px;
  font-size: 13px;
}

.remember {
  display: flex;
  align-items: center;
  gap: 7px;
  cursor: pointer;
  color: var(--text-soft);
  user-select: none;
}

.remember input {
  width: 15px;
  height: 15px;
  accent-color: var(--primary);
  cursor: pointer;
}

.forgot {
  color: var(--primary);
  text-decoration: none;
  font-weight: 500;
}

.forgot:hover {
  text-decoration: underline;
}

.btn {
  width: 100%;
  height: 46px;
  border: 0;
  border-radius: 10px;
  cursor: pointer;
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  font-family: inherit;
  letter-spacing: 1px;
  transition: transform .15s, box-shadow .2s, opacity .2s;
  box-shadow: 0 6px 18px rgba(79, 70, 229, .32);
}

.btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 10px 24px rgba(79, 70, 229, .38);
}

.btn:active {
  transform: translateY(0);
}

.btn.loading {
  opacity: .75;
  pointer-events: none;
}

.signup {
  margin-top: 24px;
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
}

.signup a {
  color: var(--primary);
  text-decoration: none;
  font-weight: 600;
}

.signup a:hover {
  text-decoration: underline;
}

@media (max-width: 780px) {
  .form-side {
    padding: 36px 32px 40px;
  }
}
</style>
