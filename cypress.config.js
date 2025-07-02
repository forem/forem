/* eslint-env node */
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:1234',
    setupNodeEvents(on, config) {
      return require('./cypress/plugins/index.js')(on, config);
    },
    screenshotsFolder: 'tmp/cypress_screenshots',
    defaultCommandTimeout: 25000,
    trashAssetsBeforeRuns: false,
    video: false,
    retries: 5,
    reporter: 'cypress-multi-reporters',
    reporterOptions: {
      configFile: 'cypress/reporter-config.json',
    },
  },
});
