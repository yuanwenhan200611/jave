import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { viteSingleFile } from 'vite-plugin-singlefile'

export default defineConfig({
  // 相对路径 + 单文件打包：dist/index.html 双击即可在浏览器打开，无需服务器
  base: './',
  plugins: [vue(), viteSingleFile()],
  server: {
    host: '127.0.0.1',
    port: 5173,
    open: false
  },
  build: {
    outDir: 'dist'
  }
})
