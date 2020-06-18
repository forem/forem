/*
 * This file is created so that it's possible to
 * Run `gitdocs serve` from root
 */

var config = require('./docs/.gitdocs.json');

module.exports = new Promise((resolve, reject) => {
  config.root = 'docs/';
  setupHost(config);
  resolve(config);
});

function fetchAppDomain() {
  const { execSync } = require('child_process');

  return execSync('rake app_domain').toString().replace(/\s/g, '');
}

function setupHost(config) {
  const appDomain = fetchAppDomain();

  if (config.host === '0.0.0.0' && appDomain) {
    config.host = appDomain;
  }
}
