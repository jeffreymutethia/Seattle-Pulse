import { defineConfig } from "cypress";

// Independent from legacy authenticated tests. CYPRESS_BASE_URL can point at
// the deployed preview; the very same spec exercises the real bundled data.
export default defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || "http://localhost:3000",
    specPattern: "cypress/e2e/demo-walkthrough.cy.ts",
    supportFile: false,
    testIsolation: true,
    setupNodeEvents(on) {
      on("before:browser:launch", (browser, launchOptions) => {
        if (browser.family === "chromium" && browser.isHeadless) {
          // Leave room around the AUT for unscaled desktop and mobile captures.
          launchOptions.args.push("--window-size=1920,1400", "--force-device-scale-factor=1");
        }
        return launchOptions;
      });
    },
  },
  viewportWidth: 1440,
  viewportHeight: 1000,
  defaultCommandTimeout: 15000,
  retries: 0,
  video: false,
});
