import path from "node:path"
import {fileURLToPath} from "node:url"
import {defineConfig} from "vite"
import solid from "vite-plugin-solid"

const thisDir = path.dirname(fileURLToPath(import.meta.url))
const repoRootDir = path.resolve(thisDir, "../../../../")
const runtimePackagePath = fileURLToPath(import.meta.resolve("@rescript/runtime/package.json"))
const runtimeDir = path.dirname(runtimePackagePath)

export default defineConfig({
  plugins: [
    solid({
      dev: true,
      hot: true,
      extensions: [".jsx", ".js", ".mjs"],
    }),
  ],
  esbuild: {
    jsx: "automatic",
    jsxImportSource: "solid-js",
  },
  optimizeDeps: {
    exclude: ["rescript-solid", "opencode-example-sdk"],
    esbuildOptions: {
      loader: {
        ".js": "jsx",
        ".mjs": "jsx",
      },
    },
  },
  resolve: {
    alias: {
      "@rescript/runtime": runtimeDir,
    },
  },
  server: {
    fs: {
      allow: [repoRootDir],
    },
  },
})
