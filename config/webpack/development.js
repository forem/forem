/* eslint-env node */

process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const environment = require('./environment');
const config = environment.toWebpackConfig();

// For more information, see https://webpack.js.org/configuration/devtool/#devtool
config.devtool = 'eval-source-map';

module.exports = config;
