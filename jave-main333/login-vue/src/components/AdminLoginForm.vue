<template>
  <main class="admin-login">
    <section class="login-card">
      <div class="card-head">
        <div class="crest" aria-hidden="true">
          <svg viewBox="0 0 48 48" fill="none" stroke="#e8c66a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M8 42V17l16-10 16 10v25" />
            <path d="M15 42V23l9-6 9 6v19" opacity=".65" />
            <path d="M20 42V31h8v11" opacity=".45" />
          </svg>
        </div>
        <h1>执事台</h1>
        <p>寂幽门 · 后台管理登录</p>
      </div>

      <form novalidate :aria-busy="loading" @submit.prevent="handleSubmit">
        <div class="field" :class="{ error: errors.username }">
          <label for="admin-username">执事账号</label>
          <div class="input-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            <input
              id="admin-username"
              ref="usernameInput"
              v-model.trim="form.username"
              type="text"
              placeholder="请输入执事账号"
              autocomplete="username"
              :aria-invalid="errors.username"
              aria-describedby="admin-username-tip"
              @input="clearError('username')"
            >
          </div>
          <div id="admin-username-tip" class="err-tip">请输入执事账号</div>
        </div>

        <div class="field" :class="{ error: errors.password }">
          <label for="admin-password">执事秘咒</label>
          <div class="input-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <rect x="3" y="11" width="18" height="11" rx="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <input
              id="admin-password"
              v-model="form.password"
              :type="showPassword ? 'text' : 'password'"
              placeholder="请输入执事秘咒"
              autocomplete="current-password"
              :aria-invalid="errors.password"
              aria-describedby="admin-password-tip"
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
          <div id="admin-password-tip" class="err-tip">请输入执事秘咒</div>
        </div>

        <div v-if="serverError" class="server-error" role="alert">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 8v5M12 16.5v.01" />
          </svg>
          <span>{{ serverError }}</span>
        </div>

        <button type="submit" class="btn" :class="{ loading }" :disabled="loading">
          <span v-if="loading" class="spinner" aria-hidden="true"></span>
          {{ loading ? '核验中…' : '执事登台' }}
        </button>
      </form>

      <p class="demo-note">初始执事账号 <b>admin</b> / <b>123456</b></p>
      <p class="back"><a href="#" @click.prevent="emit('back')">← 返回宗门</a></p>
    </section>
  </main>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useToast } from '../composables/useToast'
import { adminLogin, setAdminToken } from '../api/admin'

const emit = defineEmits(['success', 'back'])
const { showToast } = useToast()

const form = reactive({ username: '', password: '' })
const errors = reactive({ username: false, password: false })
const usernameInput = ref(null)
const showPassword = ref(false)
const loading = ref(false)
const serverError = ref('')

onMounted(() => usernameInput.value?.focus())

function clearError(key) {
  errors[key] = false
  serverError.value = ''
}

function validate() {
  errors.username = !form.username
  errors.password = !form.password
  return !errors.username && !errors.password
}

async function handleSubmit() {
  if (!validate()) return
  serverError.value = ''
  loading.value = true
  try {
    const res = await adminLogin(form.username, form.password)
    setAdminToken(res.token)
    emit('success', res)
  } catch (err) {
    serverError.value = err.message || '后台登录失败'
    showToast(serverError.value)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.admin-login {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;
}

.login-card {
  width: 100%;
  max-width: 420px;
  padding: 40px 38px 32px;
  border: 1px solid rgba(196, 154, 92, .35);
  border-radius: 18px;
  background: rgba(14, 9, 20, .90);
  box-shadow: 0 24px 60px rgba(0, 0, 0, .6), 0 0 40px rgba(139, 107, 214, .12);
  position: relative;
  overflow: hidden;
}

.login-card::before {
  content: "";
  position: absolute;
  top: 0;
  left: 12%;
  right: 12%;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(212, 175, 55, .8), rgba(185, 164, 242, .6), transparent);
}

.card-head {
  text-align: center;
  margin-bottom: 28px;
}

.crest {
  width: 52px;
  height: 52px;
  margin: 0 auto 14px;
  display: grid;
  place-items: center;
  border: 1px solid rgba(212, 175, 55, .6);
  border-radius: 14px;
  background: linear-gradient(145deg, #3b215e, #8c0f1d);
  box-shadow: 0 0 22px rgba(139, 107, 214, .3);
}

.crest svg { width: 26px; height: 26px; }

.card-head h1 {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 27px;
  letter-spacing: 6px;
  color: var(--gold-soft);
}

.card-head p {
  margin-top: 8px;
  font-size: 12px;
  letter-spacing: 2px;
  color: var(--text-dim);
}

.field { margin-bottom: 16px; }

.field label {
  display: block;
  margin-bottom: 8px;
  font-size: 13px;
  color: var(--text-soft);
  letter-spacing: 1px;
}

.input-box { position: relative; }

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
  background: var(--card-input);
  color: var(--text);
  font: inherit;
  font-size: 14px;
  outline: none;
  transition: border-color .18s, box-shadow .18s;
}

.input-box input::placeholder { color: var(--text-dim); }

.input-box input:focus {
  border-color: var(--gold);
  box-shadow: 0 0 0 4px rgba(139, 107, 214, .16);
}

.field.error .input-box input {
  border-color: var(--danger);
  background: rgba(90, 12, 24, .35);
}

.err-tip {
  display: none;
  margin-top: 6px;
  font-size: 12px;
  color: var(--danger);
}

.field.error .err-tip { display: block; }

.toggle-eye {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  width: 32px;
  height: 32px;
  border: 0;
  border-radius: 8px;
  background: none;
  color: var(--text-dim);
  cursor: pointer;
  display: grid;
  place-items: center;
  z-index: 1;
}

.toggle-eye:hover { color: var(--gold-soft); background: rgba(212, 175, 55, .1); }
.toggle-eye svg { width: 17px; height: 17px; }

.server-error {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: -2px 0 14px;
  padding: 9px 12px;
  border: 1px solid rgba(255, 77, 94, .45);
  border-radius: 9px;
  background: rgba(90, 12, 24, .32);
  color: var(--danger);
  font-size: 12px;
  line-height: 1.5;
}

.server-error svg { width: 15px; height: 15px; flex-shrink: 0; }

.btn {
  width: 100%;
  height: 48px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  margin-top: 6px;
  border: 1px solid rgba(212, 175, 55, .5);
  border-radius: 10px;
  background: linear-gradient(135deg, #3b215e 0%, #8c0f1d 60%, #c8102e 100%);
  color: #f7e9c4;
  font: inherit;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 5px;
  cursor: pointer;
  box-shadow: 0 6px 22px rgba(139, 107, 214, .25);
  transition: filter .18s, transform .15s;
}

.btn:hover { filter: brightness(1.12); transform: translateY(-1px); }
.btn:active { transform: translateY(0); }
.btn.loading { opacity: .75; pointer-events: none; }

.spinner {
  width: 14px;
  height: 14px;
  border: 2px solid rgba(247, 233, 196, .45);
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin .7s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.demo-note {
  margin-top: 18px;
  text-align: center;
  font-size: 11px;
  color: var(--text-dim);
}

.demo-note b { color: var(--gold-soft); font-weight: 600; }

.back {
  margin-top: 14px;
  text-align: center;
  font-size: 12px;
}

.back a {
  color: var(--text-soft);
  text-decoration: none;
  border-bottom: 1px dashed var(--text-dim);
}

.back a:hover { color: var(--gold-soft); }

@media (prefers-reduced-motion: reduce) {
  .spinner { animation-duration: 1.8s; }
}
</style>
