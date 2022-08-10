/* eslint-env node */

const { webpackConfig } = require('shakapacker');

// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.

switch (process.env.NODE_ENV) {
  case 'development':
    require('./development.js');
    break;
  case 'test':
    require('./test.js');
    break;
  case 'production':
    require('./production.js');
    break;
}

module.exports = webpackConfig;
