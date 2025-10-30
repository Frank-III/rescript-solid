import { defineConfig } from "vite";
import solidPlugin from "vite-plugin-solid";
import path from "path";

export default defineConfig({
  plugins: [
    solidPlugin({
      hot: true,
      dev: true,
      extensions: [".jsx", ".js", ".mjs"],
    }),
  ],
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: 'solid-js',
  },
  optimizeDeps: {
    include: ["solid-js", "solid-js/web"],
    exclude: ["rescript-solid"],
    esbuildOptions: {
      loader: {
        ".mjs": "jsx",
        ".js": "jsx",
      },
      jsx: 'automatic',
      jsxImportSource: 'solid-js',
    },
  },
  resolve: {
    alias: {
      "@rescript/runtime": path.resolve(__dirname, "../../node_modules/.bun/@rescript+runtime@12.0.0-rc.2/node_modules/@rescript/runtime")
    }
  },
  server: {
    port: 3000,
  },
});
