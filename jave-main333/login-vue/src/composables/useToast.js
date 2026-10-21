import { ref } from 'vue'

// 模块级单例：任意组件调用 showToast 都能驱动同一个 Toast 组件
const visible = ref(false)
const message = ref('')
let timer = null

export function useToast() {
  const showToast = (msg, duration = 2600) => {
    message.value = msg
    visible.value = true
    clearTimeout(timer)
    timer = setTimeout(() => {
      visible.value = false
    }, duration)
  }

  const hideToast = () => {
    clearTimeout(timer)
    visible.value = false
  }

  return { visible, message, showToast, hideToast }
}
