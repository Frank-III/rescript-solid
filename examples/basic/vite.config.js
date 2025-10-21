import { defineConfig } from 'vite'
import solidPlugin from 'vite-plugin-solid'

export default defineConfig({
  plugins: [solidPlugin({ dev: true, hot: true, extensions: ['.jsx', '.js', '.mjs'] })],
  esbuild: { loader: 'jsx', include: /\.mjs$/, exclude: [] },
  optimizeDeps: {
    include: ['solid-js', 'solid-js/web'],
    exclude: ['rescript-solid'],
    esbuildOptions: { loader: { '.mjs': 'jsx' } }
  },
  server: { port: 3000 }
})

