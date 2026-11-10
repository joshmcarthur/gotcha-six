import { defineConfig } from "vite";
import wasm from "vite-plugin-wasm";

export default defineConfig({
  plugins: [wasm()],
  server: {
    port: 5173,
  },
  optimizeDeps: {
    exclude: ["./src/wasm/gotcha_six_core.js"],
  },
  test: {
    environment: "node",
  },
});
