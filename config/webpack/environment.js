/* global require module */
const { environment } = require('@rails/webpacker');
const erb = require('./loaders/erb');

// Enable the default config
environment.splitChunks();

// We don't want babel-loader running on the node_modules folder.
environment.loaders.delete('nodeModules');

environment.loaders.append('erb', erb);

module.exports = environment;
