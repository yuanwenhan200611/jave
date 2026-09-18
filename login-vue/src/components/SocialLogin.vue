<template>
  <div class="social-area">
    <div class="divider">或使用以下方式登录</div>

    <div class="social">
      <button type="button" @click="emit('select', 'wechat')">
        <svg viewBox="0 0 24 24" fill="#07C160">
          <path d="M8.7 3C4.9 3 1.9 5.6 1.9 8.8c0 1.8 1 3.4 2.6 4.5l-.6 1.9 2.1-1.1c.9.3 1.8.4 2.7.4h.5a5.6 5.6 0 0 1-.2-1.4c0-3.2 3-5.8 6.7-5.8h.6C15.9 4.9 12.6 3 8.7 3zm-2.3 4a.9.9 0 1 1 0-1.8.9.9 0 0 1 0 1.8zm4.6 0a.9.9 0 1 1 0-1.8.9.9 0 0 1 0 1.8z" />
        </svg>
        微信
      </button>
      <button type="button" @click="emit('select', 'wecom')">
        <svg viewBox="0 0 24 24" fill="#2e7cf6">
          <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 4.5a1.3 1.3 0 1 1 0 2.6 1.3 1.3 0 0 1 0-2.6zm-3 5.2c.8 0 1.5.5 1.5 1.2s-.7 1.2-1.5 1.2-1.5-.5-1.5-1.2.7-1.2 1.5-1.2zm6 0c.8 0 1.5.5 1.5 1.2s-.7 1.2-1.5 1.2-1.5-.5-1.5-1.2.7-1.2 1.5-1.2zM12 17.8c-2.3 0-4.3-1.3-5.2-3.2h10.4c-.9 1.9-2.9 3.2-5.2 3.2z" />
        </svg>
        企业微信
      </button>
    </div>
  </div>
</template>

<script setup>
const emit = defineEmits(['select'])
</script>

<style scoped>
.divider {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 26px 0 20px;
  font-size: 12px;
  color: #9ca3af;
}

.divider::before,
.divider::after {
  content: "";
  flex: 1;
  height: 1px;
  background: var(--border);
}

.social {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.social button {
  height: 42px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: #fff;
  cursor: pointer;
  font-size: 13px;
  font-family: inherit;
  color: #374151;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: border-color .18s, background .18s;
}

.social button:hover {
  border-color: #c7cbd8;
  background: #fafafc;
}

.social svg {
  width: 17px;
  height: 17px;
}
</style>
