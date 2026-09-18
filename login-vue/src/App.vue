<template>
  <div class="wrap">
    <BrandPanel />

    <LoginForm
      @success="handleSuccess"
      @forgot="showToast('忘记密码功能待接入')"
      @signup="showToast('注册功能待接入')"
    />
  </div>

  <ToastMessage />
</template>

<script setup>
import BrandPanel from './components/BrandPanel.vue'
import LoginForm from './components/LoginForm.vue'
import ToastMessage from './components/ToastMessage.vue'
import { useToast } from './composables/useToast'

const { showToast } = useToast()

function handleSuccess(res) {
  // 登录成功后可在此跳转路由或保存 token
  console.log('登录结果：', res)
}
</script>

<style scoped>
.wrap {
  width: 100%;
  max-width: 940px;
  margin: 0 auto;
  background: var(--card);
  border-radius: 20px;
  overflow: hidden;
  display: grid;
  grid-template-columns: 1fr 1fr;
  box-shadow: 0 20px 60px rgba(31, 36, 48, .12);
}

@media (max-width: 780px) {
  .wrap {
    grid-template-columns: 1fr;
    max-width: 440px;
  }
}
</style>
