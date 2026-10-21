<template>
  <transition name="toast">
    <div v-if="visible" class="toast">
      <svg viewBox="0 0 24 24" fill="none" stroke="#4cc38a" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" width="18" height="18">
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
  background: rgba(26, 17, 34, .96);
  border: 1px solid var(--border-strong);
  border-left: 4px solid var(--gold);
  padding: 12px 22px;
  border-radius: 10px;
  font-size: 14px;
  color: var(--text);
  letter-spacing: 1px;
  box-shadow: 0 12px 34px rgba(0, 0, 0, .6), 0 0 24px rgba(200, 16, 46, .18);
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
