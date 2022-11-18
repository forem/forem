/* eslint-env node */
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      return require('./cypress/plugins/index.js')(on, config);
    },
    screenshotsFolder: 'tmp/cypress_screenshots',
    trashAssetsBeforeRuns: false,
    video: false,
    retries: 3,
    reporter: 'junit',
    reporterOptions: {
      mochaFile: 'cypress/results/results-[hash].xml',
    },
  },
});
