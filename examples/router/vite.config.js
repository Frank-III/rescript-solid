import { defineConfig } from 'vite'
import solidPlugin from 'vite-plugin-solid'
import path from 'path'
import { createRequire } from 'module'

const require = createRequire(import.meta.url)
const rescriptRuntimeDir = path.dirname(
  require.resolve('@rescript/runtime/package.json'),
)

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
    include: ['solid-js', '@solidjs/web'],
    exclude: ['rescript-solid', 'rescript-solid-router'],
    esbuildOptions: { 
      loader: { '.mjs': 'jsx', '.js': 'jsx' },
      jsx: 'automatic',
      jsxImportSource: 'solid-js',
    }
  },
  resolve: {
    alias: {
      '@rescript/runtime': rescriptRuntimeDir,
      'solid-js/web': '@solidjs/web',
      'solid-js/h': '@solidjs/h',
      'solid-js/store': 'solid-js',
    }
  },
})
