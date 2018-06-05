const { resolve } = require('path');

const rulesToAdd = [
  {
    test: /\.scss$/,
    use: [
      {
        loader: 'style-loader', // creates style nodes from JS strings
      },
      {
        loader: 'css-loader', // translates CSS into CommonJS
      },
      {
        loader: 'sass-loader', // compiles Sass to CSS
      },
    ],
  },
];

const createWebpackConfig = (storybookBaseConfig, configType) => {
  // configType has a value of 'DEVELOPMENT' or 'PRODUCTION'
  // You can change the configuration based on that.
  // 'PRODUCTION' is used when building the static version of storybook.
  const {
    module: { rules },
    plugins,
    resolve: { extensions, alias },
  } = storybookBaseConfig;

  // Make whatever fine-grained changes you need
  storybookBaseConfig.resolve.alias = {
    ...alias,
    react: 'preact-compat',
    'react-dom': 'preact-compat',
  };
  storybookBaseConfig.resolve.extensions = [...extensions, '.scss'];
  storybookBaseConfig.module.rules = [...rules].concat(rulesToAdd);

  // Return the altered config
  return storybookBaseConfig;
};

module.exports = createWebpackConfig;
