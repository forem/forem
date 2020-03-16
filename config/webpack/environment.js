/* global require module */
const { environment } = require('@rails/webpacker');
const erb = require('./loaders/erb');

environment.splitChunks(config => {
  return {
    ...config,
    optimization: {
      ...config.optimization,
      splitChunks: {
        ...config.optimization.splitChunks,
        cacheGroups: {
          vendor: {
            test: /node_modules/,
            chunks: 'initial',
            name: 'vendor',
            enforce: true,
          },
          default: {
            minChunks: 2,
            priority: -20,
            reuseExistingChunk: true,
          },
        },
      },
    },
  };
});

// We don't want babel-loader running on the node_modules folder.
environment.loaders.delete('nodeModules');

environment.loaders.append('erb', erb);

module.exports = environment;
