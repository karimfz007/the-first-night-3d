import { defineConfig, devices } from "@playwright/test";

const localBrowserChannel = process.platform === "win32" ? "chrome" : undefined;

export default defineConfig({
  testDir: "./tests/browser",
  timeout: 90_000,
  expect: { timeout: 15_000 },
  fullyParallel: false,
  workers: 1,
  reporter: [["line"]],
  use: {
    baseURL: "http://127.0.0.1:4173",
    headless: true,
    channel: localBrowserChannel,
    actionTimeout: 15_000,
    navigationTimeout: 45_000
  },
  webServer: {
    command: "node tests/browser/server.mjs builds/web",
    url: "http://127.0.0.1:4173",
    reuseExistingServer: true,
    timeout: 30_000
  },
  projects: [
    {
      name: "desktop-chromium",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1440, height: 900 }
      }
    },
    {
      name: "android-landscape",
      use: {
        browserName: "chromium",
        viewport: { width: 915, height: 412 },
        screen: { width: 915, height: 412 },
        deviceScaleFactor: 1,
        hasTouch: true,
        isMobile: true,
        userAgent: "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36"
      }
    }
  ]
});
