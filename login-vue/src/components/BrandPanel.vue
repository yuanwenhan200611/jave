<template>
  <aside class="brand">
    <div class="logo">
      <span class="logo-mark">
        <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="18" height="18">
          <path d="M12 2 4 6v6c0 5 3.4 9.4 8 10 4.6-.6 8-5 8-10V6l-8-4z" />
        </svg>
      </span>
      <span>{{ title }}</span>
    </div>

    <div class="brand-copy">
      <h1>欢迎回来<br>继续你的工作</h1>
      <p>登录后即可访问你的工作台、项目数据<br>与团队协作空间。</p>
    </div>

    <div class="brand-foot">
      © 2026 WorkBuddy<br>
      遇到问题？联系 {{ supportEmail }}
    </div>
  </aside>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    default: 'WorkBuddy 控制台'
  },
  supportEmail: {
    type: String,
    default: 'support@workbuddy.cn'
  }
})
</script>

<style scoped>
.brand {
  position: relative;
  padding: 56px 48px;
  color: #fff;
  background: linear-gradient(145deg, #4f46e5 0%, #6d5ce7 45%, #3b82f6 100%);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  overflow: hidden;
}

.brand::before,
.brand::after {
  content: "";
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, .10);
}

.brand::before {
  width: 260px;
  height: 260px;
  top: -90px;
  right: -80px;
}

.brand::after {
  width: 180px;
  height: 180px;
  bottom: -60px;
  left: -50px;
  background: rgba(255, 255, 255, .08);
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 18px;
  font-weight: 600;
  position: relative;
  z-index: 1;
}

.logo-mark {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: rgba(255, 255, 255, .22);
  display: grid;
  place-items: center;
  backdrop-filter: blur(4px);
}

.brand-copy {
  position: relative;
  z-index: 1;
  margin-top: 40px;
}

.brand-copy h1 {
  font-size: 30px;
  line-height: 1.35;
  font-weight: 700;
  letter-spacing: .5px;
}

.brand-copy p {
  margin-top: 14px;
  font-size: 14px;
  line-height: 1.8;
  color: rgba(255, 255, 255, .82);
}

.brand-foot {
  position: relative;
  z-index: 1;
  font-size: 12px;
  color: rgba(255, 255, 255, .6);
  line-height: 1.9;
}

@media (max-width: 780px) {
  .brand {
    padding: 36px 32px;
  }

  .brand-copy {
    margin-top: 24px;
  }

  .brand-copy h1 {
    font-size: 24px;
  }

  .brand-foot {
    display: none;
  }
}
</style>
