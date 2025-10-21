import { defineConfig } from 'vite'
import solidPlugin from 'vite-plugin-solid'

export default defineConfig({
  plugins: [solidPlugin({ dev: true, hot: true, extensions: ['.jsx', '.js', '.mjs'] })],
  esbuild: { loader: 'jsx', include: /\.mjs$/, exclude: [] },
  optimizeDeps: {
    include: ['solid-js', 'solid-js/web', '@solidjs/router'],
    exclude: ['rescript-solid', 'rescript-solid-router'],
    esbuildOptions: { loader: { '.mjs': 'jsx' } }
  },
  server: { port: 3001 }
})

