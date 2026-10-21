<template>
  <main class="form-side">
    <div class="form-head">
      <h2>入我魔道</h2>
      <p>斩断天命，自立道途</p>
    </div>

    <form novalidate @submit.prevent="handleSubmit">
      <div class="field" :class="{ error: errors.username }">
        <label for="reg-username">取一道号</label>
        <div class="input-box">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>
          <input
            id="reg-username"
            v-model.trim="form.username"
            type="text"
            placeholder="3-20 位字母、数字或下划线"
            autocomplete="username"
            @input="errors.username = false"
          >
        </div>
        <div class="err-tip">{{ usernameTip }}</div>
      </div>

      <div class="field" :class="{ error: errors.password }">
        <label for="reg-password">设护身秘咒</label>
        <div class="input-box">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
          <input
            id="reg-password"
            v-model="form.password"
            :type="showPassword ? 'text' : 'password'"
            placeholder="至少 6 位秘咒"
            autocomplete="new-password"
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
        <div class="err-tip">秘咒不能少于 6 位</div>
      </div>

      <div class="field" :class="{ error: errors.confirm }">
        <label for="reg-confirm">再诵一遍秘咒</label>
        <div class="input-box">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M9 12l2 2 4-4" />
            <rect x="3" y="11" width="18" height="11" rx="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
          <input
            id="reg-confirm"
            v-model="form.confirm"
            :type="showPassword ? 'text' : 'password'"
            placeholder="请再次输入秘咒"
            autocomplete="new-password"
            @input="errors.confirm = false"
          >
        </div>
        <div class="err-tip">两次输入的秘咒不一致</div>
      </div>

      <div class="field" :class="{ error: errors.captcha }">
        <label for="reg-captcha">渡劫法印</label>
        <div class="captcha-box">
          <div class="input-box captcha-input">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="3" width="18" height="18" rx="2" />
              <path d="M8 9v6M12 9v6M16 9v6" opacity=".8" />
            </svg>
            <input
              id="reg-captcha"
              v-model.trim="form.captcha"
              type="text"
              placeholder="请输入右侧字符"
              maxlength="4"
              autocomplete="off"
              @input="errors.captcha = false"
            >
          </div>
          <img
            v-if="captchaImage"
            :src="captchaImage"
            class="captcha-img"
            alt="验证码"
            title="看不清？点击刷新"
            @click="refreshCaptcha"
          >
          <div v-else class="captcha-img captcha-loading" @click="refreshCaptcha">加载中…</div>
        </div>
        <div class="err-tip">{{ captchaTip }}</div>
      </div>

      <button type="submit" class="btn" :class="{ loading }" :disabled="loading">
        {{ loading ? '证道中…' : '证 道' }}
      </button>
    </form>

    <p class="signup">已有名号？<a href="#" @click.prevent="emit('back')">返回登临</a></p>
  </main>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useToast } from '../composables/useToast'
import { register, getCaptcha } from '../api/auth'

const emit = defineEmits(['back', 'success'])

const { showToast } = useToast()

const form = reactive({
  username: '',
  password: '',
  confirm: '',
  captcha: ''
})

const errors = reactive({
  username: false,
  password: false,
  confirm: false,
  captcha: false
})

const usernameTip = ref('请输入道号')
const captchaTip = ref('请输入法印字符')
const showPassword = ref(false)
const loading = ref(false)

// 后端验证码：captchaId 用于提交校验，image 为 base64 图片
const captchaId = ref('')
const captchaImage = ref('')

async function refreshCaptcha() {
  try {
    const data = await getCaptcha()
    captchaId.value = data.captchaId
    captchaImage.value = data.image
  } catch (err) {
    showToast(err.message || '获取法印失败')
  }
  form.captcha = ''
  errors.captcha = false
}

onMounted(refreshCaptcha)

function validate() {
  if (!form.username) {
    usernameTip.value = '请输入道号'
    errors.username = true
  } else if (!/^[A-Za-z0-9_]{3,20}$/.test(form.username)) {
    usernameTip.value = '道号需为 3-20 位字母、数字或下划线'
    errors.username = true
  }

  errors.password = form.password.length < 6
  errors.confirm = form.confirm !== form.password || !form.confirm

  // 验证码是否正确由后端校验，前端只做非空检查
  if (!form.captcha) {
    captchaTip.value = '请输入法印字符'
    errors.captcha = true
  }

  return !errors.username && !errors.password && !errors.confirm && !errors.captcha
}

async function handleSubmit() {
  if (!validate()) return

  loading.value = true
  try {
    const res = await register({
      username: form.username,
      password: form.password,
      captchaId: captchaId.value,
      captcha: form.captcha
    })
    showToast(`证道成功，恭迎 ${res.username} 道友入宗`)
    emit('success', res)
  } catch (err) {
    showToast(err.message || '证道失败，请稍后重试')
    refreshCaptcha() // 注册失败（含验证码错误）后自动换一张
  } finally {
    loading.value = false
  }
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

form {
  margin-top: 24px;
}

.field {
  margin-bottom: 16px;
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

.field.error .input-box input,
.field.error .captcha-img {
  border-color: var(--danger);
}

.field.error .input-box input {
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

/* 验证码行：输入框 + 图片并排 */
.captcha-box {
  display: flex;
  gap: 12px;
  align-items: center;
}

.captcha-input {
  flex: 1;
}

.captcha-img {
  width: 112px;
  height: 46px;
  flex-shrink: 0;
  border: 1px solid var(--border);
  border-radius: 10px;
  cursor: pointer;
  background: #efeaf6;
  transition: border-color .18s;
  display: block;
  object-fit: cover;
}

.captcha-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  color: var(--text-dim);
  user-select: none;
}

.captcha-img:hover {
  border-color: var(--gold);
}

.btn {
  width: 100%;
  height: 48px;
  margin-top: 6px;
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

.signup {
  margin-top: 20px;
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
}
</style>
