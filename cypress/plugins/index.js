/// <reference types="cypress" />
/* eslint-env node */

// ***********************************************************
// This example plugins/index.js can be used to load plugins
//
// You can change the location of this file or turn off loading
// the plugins file with the 'pluginsFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/plugins-guide
// ***********************************************************

// This function is called when a project is opened or re-opened (e.g. due to
// the project's config changing)

/**
 * @type {Cypress.PluginConfig}
 */
module.exports = (on, config) => {
  // `on` is used to hook into various events Cypress emits
  // `config` is the resolved Cypress config

  on('task', {
    resetData() {
      // Check the console where Cypress is running for the specific error.
      // The actual error will not appear in the Cypress test runner.
      const { spawnSync } = require('child_process');
      const { status: curlStatus, stderr: curlError } = spawnSync('curl', [
        '-XDELETE',
        `${config.env.ELASTICSEARCH_URL}/\\*`,
      ]);

      if (curlStatus !== 0) {
        throw curlError;
      }

      const { status, stderr } = spawnSync('bundle', [
        'exec',
        'rails db:truncate_all',
      ]);

      if (status !== 0) {
        throw stderr.toString('utf8');
      }

      return status;
    },
  });
};
