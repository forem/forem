/* global require module */
const { environment } = require('@rails/webpacker');
const erb = require('./loaders/erb');

// config/webpack/environment.js
const WebpackAssetsManifest = require('webpack-assets-manifest');

// Should override the existing manifest plugin
environment.plugins.insert(
  'Manifest',
  new WebpackAssetsManifest({
    entrypoints: true, // default in rails is false
    writeToDisk: true, // rails defaults copied from webpacker
    publicPath: true, // rails defaults copied from webpacker
  }),
);

// Enable the default config
environment.splitChunks();

// We don't want babel-loader running on the node_modules folder.
environment.loaders.delete('nodeModules');

environment.loaders.append('erb', erb);

module.exports = environment;
