<template>
  <!-- 全屏背景层：所有页面（登录 / 注册 / 宗门各堂）共用同一张魔宗背景图 -->
  <div class="app-bg" aria-hidden="true">
    <img class="app-bg-img" src="./assets/bg-main.jpg" alt="">
    <div class="app-bg-veil"></div>
  </div>

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

    <!-- 登录后的宗门各堂：首页 / 秘境 / 功法阁 / 宗门榜 / 论道 / 洞府 -->
    <HomePage
      v-else-if="view === 'home'"
      :username="currentUser"
      :search-seed="searchSeed"
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
      v-else-if="view === 'forum'"
      :username="currentUser"
      @nav="goSect"
      @logout="handleLogout"
    />

    <!-- 洞府：个人档案页（与论道/首页/用户数据联动） -->
    <ProfilePage
      v-else
      :username="currentUser"
      @nav="goSect"
      @logout="handleLogout"
      @search="handleSearchSeed"
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
import ProfilePage from './components/ProfilePage.vue'
import ToastMessage from './components/ToastMessage.vue'
import { useToast } from './composables/useToast'

const { showToast } = useToast()

// 视图状态机：'login' | 'register' | 'home' | 'secret' | 'skill' | 'rank' | 'forum' | 'profile'
// 未引入 vue-router，宗门各堂沿用 view 状态机切换
const view = ref('login')
const lastUsername = ref('')
const currentUser = ref('')
// 洞府「再寻一次」联动：跳回首页并自动搜索的关键词
const searchSeed = ref('')

/** 登录后的六个宗门页面共用全宽面板样式 */
const SECT_VIEWS = ['home', 'secret', 'skill', 'rank', 'forum', 'profile']
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
  if (key === 'home') searchSeed.value = '' // 离开首页时清空搜索种子
  view.value = SECT_VIEWS.includes(key) ? key : 'home'
}

/** 洞府「再寻一次」：跳回首页并自动执行搜索（同词重复点击也能触发） */
function handleSearchSeed(keyword) {
  view.value = 'home'
  searchSeed.value = ''
  requestAnimationFrame(() => { searchSeed.value = keyword || '' })
}

function handleLogout() {
  localStorage.removeItem('token')
  localStorage.removeItem('username')
  currentUser.value = ''
  view.value = 'login'
}
</script>

<style scoped>
/* ===== 全屏背景层（所有页面共用） =====
   背景图 bg-main.jpg 1728×1080：object-fit: cover 等比铺满整个视口，
   屏幕比例与 16:10 不一致时只裁掉少量边缘，绝不拉伸变形、绝不留白。 */
.app-bg {
  position: fixed;
  inset: 0;
  z-index: 0;
  overflow: hidden;
  pointer-events: none;
  background: #0a0710;
}

.app-bg-img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  /* 背景略偏下：底部骷髅堆是画面主体，尽量多露出来 */
  object-position: center 65%;
  /* 微微放大，避免取整后边缘露出 1px 细缝 */
  transform: scale(1.02);
  /* 整体提亮，骷髅细节更清晰 */
  filter: brightness(1.08) saturate(1.08) contrast(1.02);
}

/* 可读性遮罩：只在顶部导航区稍压暗，底部大面积放亮让骷髅可见 */
.app-bg-veil {
  position: absolute;
  inset: 0;
  background-image:
    radial-gradient(rgba(255, 255, 255, .03) 1px, transparent 1px),
    linear-gradient(180deg,
      rgba(8, 5, 12, .50) 0%,
      rgba(8, 5, 12, .22) 18%,
      rgba(8, 5, 12, .06) 40%,
      rgba(8, 5, 12, .06) 75%,
      rgba(8, 5, 12, .26) 100%),
    radial-gradient(1100px 560px at 12% -12%, rgba(200, 16, 46, .14), transparent 60%),
    radial-gradient(900px 520px at 100% 120%, rgba(123, 15, 29, .14), transparent 55%);
  background-size: 26px 26px, auto, auto, auto;
  background-position: top left, center, center, center;
  background-repeat: repeat, no-repeat, no-repeat, no-repeat;
}

.wrap {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 960px;
  margin: 0 auto;
  /* 登录/注册：只留一层薄暗底保证表单可读，背景仍透出来 */
  background: rgba(8, 5, 12, .40);
  border: 1px solid rgba(196, 154, 92, .28);
  border-radius: 22px;
  overflow: hidden;
  display: grid;
  grid-template-columns: 1fr 1fr;
  box-shadow:
    0 0 0 1px rgba(212, 175, 55, .06),
    0 24px 60px rgba(0, 0, 0, .55),
    0 0 50px rgba(200, 16, 46, .12);
}

/* 首页与宗门四堂：外层容器完全透明，由内部 .home/.page 面板负责遮罩，
   避免两层深色叠在一起把背景压死 */
.wrap.is-home {
  display: block;
  max-width: 1320px;
  background: transparent;
  border: none;
  border-radius: 0;
  box-shadow: none;
  overflow: visible;
}

@media (max-width: 780px) {
  .wrap {
    grid-template-columns: 1fr;
    max-width: 440px;
  }
}
</style>
