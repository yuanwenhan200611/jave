<template>
  <transition name="toast">
    <div v-if="visible" class="toast">
      <svg viewBox="0 0 24 24" fill="none" stroke="#059669" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" width="18" height="18">
        <polyline points="20 6 9 17 4 12" />
      </svg>
      <span>{{ message }}</span>
    </div>
  </transition>
</template>

<script setup>
import { useToast } from '../composables/useToast'

const { visible, message } = useToast()
</script>

<style scoped>
.toast {
  position: fixed;
  top: 24px;
  left: 50%;
  transform: translate(-50%, 0);
  background: #fff;
  border-left: 4px solid var(--success);
  padding: 12px 20px;
  border-radius: 10px;
  font-size: 14px;
  box-shadow: 0 10px 30px rgba(31, 36, 48, .16);
  display: flex;
  align-items: center;
  gap: 9px;
  z-index: 99;
}

.toast-enter-active,
.toast-leave-active {
  transition: opacity .25s, transform .25s;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translate(-50%, -16px);
}
</style>
