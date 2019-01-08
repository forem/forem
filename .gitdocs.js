/*
 * This file is created so that it's possible to
 * Run `gitdocs serve` from root
 */

var config = require('./docs/.gitdocs.json');

module.exports = new Promise((resolve, reject) => {
  config.root = 'docs/';
  resolve(config);
});
