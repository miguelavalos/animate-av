import tailwindcss from "@tailwindcss/vite";
import { tanstackStart } from "@tanstack/react-start/plugin/vite";
import viteReact from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";

const animateConvexUrl = process.env.VITE_ANIMATEAV_CONVEX_URL ?? process.env.ANIMATEAV_CONVEX_URL ?? "";

export default defineConfig({
  define: {
    "import.meta.env.VITE_ANIMATEAV_CONVEX_URL": JSON.stringify(animateConvexUrl)
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks(id: string) {
          if (!id.includes("node_modules")) {
            return undefined;
          }
          if (id.includes("/react/") || id.includes("/react-dom/") || id.includes("/scheduler/")) {
            return "vendor-react";
          }
          if (id.includes("/@tanstack/")) {
            return "vendor-tanstack";
          }
          if (id.includes("/@clerk/react/")) {
            return "vendor-clerk-react";
          }
          if (id.includes("/@clerk/shared/")) {
            return "vendor-clerk-shared";
          }
          if (id.includes("/@clerk/localizations/")) {
            return "vendor-clerk-localizations";
          }
          if (id.includes("/@clerk/tanstack-react-start/")) {
            return "vendor-clerk-tanstack";
          }
          if (id.includes("/lucide-react/") || id.includes("/sonner/") || id.includes("/@radix-ui/")) {
            return "vendor-ui";
          }
          if (id.includes("/seroval/")) {
            return "vendor-serialization";
          }
          return undefined;
        }
      }
    }
  },
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url))
    },
    preserveSymlinks: true
  },
  server: {
    port: 5195
  },
  plugins: [tanstackStart(), viteReact(), tailwindcss()]
});
