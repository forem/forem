/* eslint-env node */

const path = require('path');
const { environment } = require('@rails/webpacker');
const HoneybadgerSourceMapPlugin = require('@honeybadger-io/webpack');
const erb = require('./loaders/erb');

/*
The customizations below are to create the vendor chunk. The vendor chunk is no longer consumed like it was in webpacker 3.
There is no longer one vendor bundle. It gets code split based on what webpacker packs need. All the object spreading e.g. `...config.optimization` is to keep
the existing configuration and only override/add what is necessary.

The cache groups section is the default cache groups in webpack 4. See https://webpack.js.org/plugins/split-chunks-plugin/#optimizationsplitchunks.
It does not appear to be the default with webpacker 4.
*/
environment.splitChunks((config) => {
  return {
    ...config,
    resolve: {
      ...config.resolve,
      alias: {
        ...(config.resolve ? config.resolve.alias : {}),
        '@crayons': path.resolve(__dirname, '../../app/javascript/crayons'),
        '@utilities': path.resolve(__dirname, '../../app/javascript/utilities'),
        '@components': path.resolve(
          __dirname,
          '../../app/javascript/shared/components',
        ),
      },
    },
  };
});

// We don't want babel-loader running on the node_modules folder.
environment.loaders.delete('nodeModules');

environment.loaders.append('erb', erb);

if (process.env.HONEYBADGER_API_KEY && process.env.ASSETS_URL) {
  environment.plugins.append(
    'HoneybadgerSourceMap',
    new HoneybadgerSourceMapPlugin({
      apiKey: process.env.HONEYBADGER_API_KEY,
      assetsUrl: process.env.ASSETS_URL,
      silent: false,
      ignoreErrors: false,
      revision:
        process.env.RELEASE_FOOTPRINT ||
        process.env.HEROKU_SLUG_COMMIT ||
        'master',
    }),
  );
}

module.exports = environment;
