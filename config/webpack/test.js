const environment = require('./environment');

const config = environment.toWebpackConfig();

config.stats = 'errors-only';

module.exports = config;
