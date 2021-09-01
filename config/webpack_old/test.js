/* eslint-env node */

process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const environment = require('./environment');

const config = environment.toWebpackConfig();

config.stats = 'errors-only';

module.exports = config;
