import { defineConfig } from "vite";
import solidPlugin from "vite-plugin-solid";

export default defineConfig({
  plugins: [
    solidPlugin({
      hot: true,
      dev: true,
      extensions: [".jsx", ".js", ".mjs"],
    }),
  ],
  esbuild: {
    // Transform .mjs files as JSX
    loader: "jsx",
    include: /\.mjs$/,
    exclude: [],
  },
  optimizeDeps: {
    include: ["solid-js", "solid-js/web"],
    exclude: ["rescript/solid"],
    esbuildOptions: {
      // Ensure .mjs files are treated as JSX
      loader: {
        ".mjs": "jsx",
      },
    },
  },
  server: {
    port: 3000,
  },
});
