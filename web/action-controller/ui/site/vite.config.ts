import { resolve } from 'path'
import { defineConfig } from 'vite'

// https://vitejs.dev/config/
export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        custom_404: resolve(__dirname, 'custom_404.html'),
        custom_50x: resolve(__dirname, 'custom_50x.html'),
        pricing: resolve(__dirname, 'planos.html'),
      },
    },
  },
})
