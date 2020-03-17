/* global require module */
const { environment } = require('@rails/webpacker');
const erb = require('./loaders/erb');

/*
The customizations below are to create the vendor chunk. The vendor chunk is no longer consumed like it was in webpacker 3.
There is no longer one vendor bundle. It gets code split based on what webpacker packs need. All the object spreading e.g. `...config.optimization` is to keep
the existing configuration and only override/add what is necessary.

The cache groups section is the default cache groups in webpack 4. See https://webpack.js.org/plugins/split-chunks-plugin/#optimizationsplitchunks.
It does not appear to be the default with webpacker 4.
*/
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
