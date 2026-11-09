<template>
  <div class="wrap" :class="{ 'is-home': isSectView }">
    <BrandPanel v-if="!isSectView" />

    <LoginForm
      v-if="view === 'login'"
      :initial-username="lastUsername"
      @success="handleSuccess"
      @forgot="showToast('忘记密码功能待接入')"
      @signup="view = 'register'"
    />

    <RegisterForm
      v-else-if="view === 'register'"
      @back="view = 'login'"
      @success="handleRegistered"
    />

    <!-- 登录后的宗门四堂：首页 / 秘境 / 功法阁 / 宗门榜 / 论道 -->
    <HomePage
      v-else-if="view === 'home'"
      :username="currentUser"
      @nav="goSect"
      @logout="handleLogout"
    />

    <SecretPage
      v-else-if="view === 'secret'"
      :username="currentUser"
      @nav="goSect"
      @logout="handleLogout"
    />

    <SkillPage
      v-else-if="view === 'skill'"
      :username="currentUser"
      @nav="goSect"
      @logout="handleLogout"
    />

    <RankPage
      v-else-if="view === 'rank'"
      :username="currentUser"
      @nav="goSect"
      @logout="handleLogout"
    />

    <ForumPage
      v-else
      :username="currentUser"
      @nav="goSect"
      @logout="handleLogout"
    />
  </div>

  <ToastMessage />
</template>

<script setup>
import { computed, ref } from 'vue'
import BrandPanel from './components/BrandPanel.vue'
import LoginForm from './components/LoginForm.vue'
import RegisterForm from './components/RegisterForm.vue'
import HomePage from './components/HomePage.vue'
import SecretPage from './components/SecretPage.vue'
import SkillPage from './components/SkillPage.vue'
import RankPage from './components/RankPage.vue'
import ForumPage from './components/ForumPage.vue'
import ToastMessage from './components/ToastMessage.vue'
import { useToast } from './composables/useToast'

const { showToast } = useToast()

// 视图状态机：'login' | 'register' | 'home' | 'secret' | 'skill' | 'rank' | 'forum'
// 未引入 vue-router，宗门各堂沿用 view 状态机切换
const view = ref('login')
const lastUsername = ref('')
const currentUser = ref('')

/** 登录后的五个宗门页面共用全宽面板样式 */
const SECT_VIEWS = ['home', 'secret', 'skill', 'rank', 'forum']
const isSectView = computed(() => SECT_VIEWS.includes(view.value))

// 打开永远是登录页；登录成功后才进入首页（不读取旧 token 自动续登）

function handleSuccess(res) {
  // 登录成功：保存会话并跳转首页
  currentUser.value = res.username
  lastUsername.value = res.username
  localStorage.setItem('token', res.token)
  localStorage.setItem('username', res.username)
  view.value = 'home'
}

function handleRegistered(res) {
  // 注册成功：记住用户名，切回登录页并自动填入
  lastUsername.value = res.username
  view.value = 'login'
  showToast('请使用新账号登录')
}

function goSect(key) {
  view.value = SECT_VIEWS.includes(key) ? key : 'home'
}

function handleLogout() {
  localStorage.removeItem('token')
  localStorage.removeItem('username')
  currentUser.value = ''
  view.value = 'login'
}
</script>

<style scoped>
.wrap {
  width: 100%;
  max-width: 960px;
  margin: 0 auto;
  background: var(--card-solid);
  border: 1px solid var(--border-strong);
  border-radius: 22px;
  overflow: hidden;
  display: grid;
  grid-template-columns: 1fr 1fr;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .10),
    0 30px 80px rgba(0, 0, 0, .65),
    0 0 60px rgba(200, 16, 46, .18);
  backdrop-filter: blur(6px);
}

/* 首页与宗门四堂为全宽大面板，不再用左右分栏 */
.wrap.is-home {
  display: block;
  max-width: 1320px;
}

@media (max-width: 780px) {
  .wrap {
    grid-template-columns: 1fr;
    max-width: 440px;
  }
}
</style>
