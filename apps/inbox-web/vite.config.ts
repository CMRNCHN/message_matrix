import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import path from "node:path";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@message-matrix/shared": path.resolve(
        __dirname,
        "../../packages/shared/src",
      ),
      "@tauri-apps/plugin-store": path.resolve(
        __dirname,
        "../../packages/shared/src/storage/tauri-stub.ts",
      ),
      "@tauri-apps/plugin-notification": path.resolve(
        __dirname,
        "../../packages/shared/src/storage/tauri-stub.ts",
      ),
    },
  },
  server: {
    port: 5173,
    host: true,
  },
  build: {
    outDir: "dist",
    sourcemap: true,
  },
});
