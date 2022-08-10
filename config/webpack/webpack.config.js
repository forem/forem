/* eslint-env node */

const { env, webpackConfig } = require('shakapacker');
const { existsSync } = require('fs');
const { resolve } = require('path');

const envSpecificConfig = () => {
  const path = resolve(__dirname, `${env.nodeEnv}.js`);
  if (existsSync(path)) {
    // console.log(`Loading ENV specific webpack configuration file ${path}`)
    return require(path);
  } else {
    return webpackConfig;
  }
};

const webpackConfiguration = envSpecificConfig();

// To debug the webpack configuration
// 1. Uncomment debugger line below
// 2. Run `bin/webpacker --debug-webpacker`
// 3. Examine the webpackConfiguration variable
// 4. Consider adding a 'debugger` line to the beginning of this file.
// debugger

module.exports = webpackConfiguration;

// switch (process.env.NODE_ENV) {
//   case 'development':
//     require('./development.js');
//     break;
//   case 'test':
//     require('./test.js');
//     break;
//   case 'production':
//     require('./production.js');
//     break;
// }

// module.exports = webpackConfig;
