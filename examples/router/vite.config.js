import { defineConfig } from 'vite'
import solidPlugin from 'vite-plugin-solid'
import path from 'path'

export default defineConfig({
  plugins: [
    solidPlugin({ 
      dev: true, 
      hot: true, 
      extensions: ['.jsx', '.js', '.mjs'] 
    })
  ],
  esbuild: { 
    jsx: 'automatic',
    jsxImportSource: 'solid-js',
  },
  optimizeDeps: {
    include: ['solid-js', 'solid-js/web', '@solidjs/router'],
    exclude: ['rescript-solid', 'rescript-solid-router'],
    esbuildOptions: { 
      loader: { '.mjs': 'jsx', '.js': 'jsx' },
      jsx: 'automatic',
      jsxImportSource: 'solid-js',
    }
  },
  resolve: {
    alias: {
      "@rescript/runtime": path.resolve(__dirname, "../../node_modules/.bun/@rescript+runtime@12.0.0-rc.2/node_modules/@rescript/runtime")
    }
  },
})
