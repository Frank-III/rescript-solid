import { defineConfig } from 'vite'
import solidPlugin from 'vite-plugin-solid'

export default defineConfig({
  plugins: [
    solidPlugin({
      hot: true,
      dev: true,
      extensions: ['.jsx', '.js', '.mjs']
    })
  ],
  esbuild: {
    include: /src\/.*\.mjs$/,
    loader: 'jsx'
  },
  optimizeDeps: {
    // Exclude our source files from pre-bundling so vite-plugin-solid processes them
    entries: [],
    include: ['solid-js', 'solid-js/web', 'solid-js/h'],
    esbuildOptions: {
      loader: {
        '.mjs': 'jsx'
      }
    }
  },
  server: {
    port: 3000
  }
})