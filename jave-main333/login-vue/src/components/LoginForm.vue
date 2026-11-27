<template>
  <main class="form-side">
    <div class="form-head">
      <h2>寂幽登临</h2>
      <p>幽门夜启，静候道友</p>
    </div>

    <form novalidate :aria-busy="loading" @submit.prevent="handleSubmit">
      <div class="field" :class="{ error: errors.username }">
        <label for="username">道号 / 法名</label>
        <div class="input-box">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>
          <input
            id="username"
            ref="usernameInput"
            v-model.trim="form.username"
            type="text"
            placeholder="请输入道号或法名"
            autocomplete="username"
            :aria-invalid="errors.username"
            aria-describedby="username-tip"
            @input="clearError('username')"
          >
        </div>
        <div id="username-tip" class="err-tip">{{ usernameTip }}</div>
      </div>

      <div class="field" :class="{ error: errors.password }">
        <label for="password">护身秘咒</label>
        <div class="input-box">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
          <input
            id="password"
            v-model="form.password"
            :type="showPassword ? 'text' : 'password'"
            placeholder="请输入护身秘咒"
            autocomplete="current-password"
            :aria-invalid="errors.password"
            aria-describedby="password-tip"
            @input="clearError('password')"
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
        <div id="password-tip" class="err-tip">{{ passwordTip }}</div>
      </div>

      <div v-if="serverError" class="server-error" role="alert">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <circle cx="12" cy="12" r="9" />
          <path d="M12 8v5M12 16.5v.01" />
        </svg>
        <span>{{ serverError }}</span>
      </div>

      <div v-if="showForgot" class="forgot-panel" role="note">
        <p>此间暂未开放秘咒重置。若遗忘秘咒，可先用试炼道号 <b>admin / test</b>（秘咒 <b>123456</b>）登临；自设道号需联系宗门执事重置。</p>
        <button type="button" @click="showForgot = false">知道了</button>
      </div>

      <div class="row-between">
        <label class="remember" title="记住道号，下次打开自动填入">
          <input id="remember" v-model="form.remember" type="checkbox"> 刻入魂印
        </label>
        <a href="#" class="forgot" @click.prevent="showForgot = !showForgot">{{ showForgot ? '收起提示' : '秘咒失传？' }}</a>
      </div>

      <button type="submit" class="btn" :class="{ loading }" :disabled="loading">
        <span v-if="loading" class="spinner" aria-hidden="true"></span>
        {{ loading ? '登临中…' : '登 临' }}
      </button>
    </form>

    <p class="signup">尚无名号？<a href="#" @click.prevent="emit('signup')">即刻入宗</a></p>
  </main>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useToast } from '../composables/useToast'
import { login } from '../api/auth'

// 只记住道号，不存密码；后端目前不消费 remember 字段，持久化逻辑放在前端
const REMEMBER_KEY = 'jiyou_remembered_username'

const props = defineProps({
  // 注册成功后回填用户名（可选）
  initialUsername: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['success', 'signup'])

const { showToast } = useToast()

const form = reactive({
  username: props.initialUsername,
  password: '',
  remember: Boolean(props.initialUsername)
})

const errors = reactive({
  username: false,
  password: false
})

const usernameTip = ref('请输入道号或法名')
const passwordTip = ref('秘咒不能少于 6 位')
const serverError = ref('')
const showForgot = ref(false)
const usernameInput = ref(null)
const showPassword = ref(false)
const loading = ref(false)

onMounted(() => {
  if (!form.username) usernameInput.value?.focus()
})

function clearError(key) {
  errors[key] = false
  serverError.value = ''
}

function validate() {
  errors.username = !form.username
  usernameTip.value = errors.username ? '请输入道号或法名' : ''

  errors.password = form.password.length < 6
  passwordTip.value = errors.password ? '秘咒不能少于 6 位' : ''

  return !errors.username && !errors.password
}

async function handleSubmit() {
  if (!validate()) return

  serverError.value = ''
  loading.value = true
  try {
    const res = await login({
      username: form.username,
      password: form.password,
      remember: form.remember
    })

    if (form.remember) localStorage.setItem(REMEMBER_KEY, form.username)
    else localStorage.removeItem(REMEMBER_KEY)

    showToast(`登临成功，恭迎 ${res.username} 道友`)
    emit('success', res)
  } catch (err) {
    const message = err.message || '登临失败，请稍后重试'
    // 行内提示 + toast 双保险：toast 一闪而过，错误原因留在表单里
    serverError.value = message
    showToast(message)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.form-side {
  position: relative;
  overflow: hidden;
  padding: 56px 52px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

/* 表单侧的淡墨字：只作氛围，不抢输入焦点 */
.form-side::before {
  content: "幽";
  position: absolute;
  right: -30px;
  bottom: -76px;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 280px;
  line-height: 1;
  font-weight: 700;
  color: rgba(139, 107, 214, .05);
  pointer-events: none;
  user-select: none;
  z-index: 0;
}

.form-side > * {
  position: relative;
  z-index: 1;
}

.form-head h2 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 27px;
  font-weight: 700;
  letter-spacing: 6px;
  color: var(--gold-soft);
  text-shadow: 0 2px 16px rgba(200, 16, 46, .4);
}

.form-head p {
  margin-top: 8px;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 2px;
}

/* 标题下的渐变细线，呼应门匾描边 */
.form-head::after {
  content: "";
  display: block;
  width: 54px;
  height: 1px;
  margin-top: 14px;
  background: linear-gradient(90deg, var(--gold), rgba(185, 164, 242, .55), transparent);
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
  color: var(--text-soft);
  letter-spacing: 1px;
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
  color: var(--text-dim);
  pointer-events: none;
  z-index: 1;
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
  background: var(--card-input);
  transition: border-color .18s, box-shadow .18s, background .18s;
  outline: none;
}

.input-box input::placeholder {
  color: var(--text-dim);
}

.input-box input:focus {
  border-color: var(--gold);
  background: rgba(28, 18, 36, .9);
  box-shadow: 0 0 0 4px rgba(200, 16, 46, .18), 0 0 14px rgba(212, 175, 55, .16);
}

.field.error .input-box input {
  border-color: var(--danger);
  background: rgba(90, 12, 24, .35);
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
  color: var(--text-dim);
  display: grid;
  place-items: center;
  border-radius: 8px;
  z-index: 1;
}

.toggle-eye:hover {
  color: var(--gold-soft);
  background: rgba(212, 175, 55, .12);
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

/* 服务端返回的错误：行内常驻，避免 toast 消失后用户不知道哪里错了 */
.server-error {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: -4px 0 14px;
  padding: 9px 12px;
  border: 1px solid rgba(255, 77, 94, .45);
  border-radius: 9px;
  background: rgba(90, 12, 24, .32);
  color: var(--danger);
  font-size: 12px;
  line-height: 1.5;
}

.server-error svg {
  width: 15px;
  height: 15px;
  flex-shrink: 0;
}

/* 「秘咒失传」展开说明：没有重置接口时，把可用出路讲清楚 */
.forgot-panel {
  margin: -4px 0 14px;
  padding: 12px 14px;
  border: 1px solid rgba(185, 164, 242, .35);
  border-radius: 10px;
  background: rgba(139, 107, 214, .10);
  font-size: 12px;
  line-height: 1.8;
  color: var(--text-soft);
}

.forgot-panel p {
  margin: 0;
}

.forgot-panel b {
  color: var(--violet-soft);
  font-weight: 600;
}

.forgot-panel button {
  margin-top: 6px;
  padding: 2px 0;
  border: 0;
  border-bottom: 1px dashed var(--violet-soft);
  background: none;
  color: var(--violet-soft);
  font: inherit;
  cursor: pointer;
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
  color: var(--gold-soft);
  text-decoration: none;
  font-weight: 500;
}

.forgot:hover {
  text-decoration: underline;
}

.btn {
  width: 100%;
  height: 48px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 10px;
  cursor: pointer;
  background: linear-gradient(135deg, #8c0f1d 0%, #c8102e 55%, #e23a4e 100%);
  color: #f7e9c4;
  font-size: 16px;
  font-weight: 700;
  font-family: inherit;
  letter-spacing: 6px;
  transition: transform .15s, box-shadow .2s, opacity .2s, filter .2s;
  box-shadow: 0 6px 22px rgba(200, 16, 46, .4), inset 0 0 12px rgba(0, 0, 0, .3);
  text-shadow: 0 1px 6px rgba(0, 0, 0, .5);
}

.btn:hover {
  transform: translateY(-1px);
  filter: brightness(1.12);
  box-shadow: 0 10px 28px rgba(200, 16, 46, .5);
}

.btn:active {
  transform: translateY(0);
}

.btn.loading {
  opacity: .75;
  pointer-events: none;
}

.spinner {
  width: 14px;
  height: 14px;
  border: 2px solid rgba(247, 233, 196, .45);
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin .7s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@media (prefers-reduced-motion: reduce) {
  .spinner { animation-duration: 1.8s; }
}

.signup {
  margin-top: 24px;
  text-align: center;
  font-size: 13px;
  color: var(--text-soft);
}

.signup a {
  color: var(--gold-soft);
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

  .form-side::before {
    font-size: 200px;
    right: -20px;
    bottom: -58px;
  }
}
</style>
