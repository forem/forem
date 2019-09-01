// const { environment } = require('@rails/webpacker');
// const customConfig = require('./custom');

// environment.config.set('resolve.extensions', ['.foo', '.bar']);
// environment.config.set('output.filename', '[name].js');
const { environment } = require('@rails/webpacker');
const WebpackAssetsManifest = require('webpack-assets-manifest');

// Enable the default config
environment.splitChunks();

// Remove the next lineif you want to transpile node modules
environment.loaders.delete('nodeModules');

module.exports = environment;
