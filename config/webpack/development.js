/* eslint-env node */

process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const environment = require('./environment');

const config = environment.toWebpackConfig();

// For more information, see https://webpack.js.org/configuration/devtool/#devtool
config.devtool = 'eval-source-map';

// Inject the preact/debug import into all the webpacker pack files (webpack entry points) that reference at least one Preact component
// so that Preact compoonents can be debugged with the Preact DevTools.
config.entry = Object.entries(config.entry).reduce(
  (previous, [entryPointName, entryPointFileName]) => {
    if (/\.jsx$/.test(entryPointFileName)) {
      previous[entryPointName] = ['preact/debug', entryPointFileName];
    } else {
      previous[entryPointName] = entryPointFileName;
    }

    return previous;
  },
  {},
);

module.exports = config;
