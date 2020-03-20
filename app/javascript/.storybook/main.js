const path = require('path');

module.exports = {
  stories: ['../**/__stories__/*.stories.jsx'],
  addons: [
    '@storybook/addon-knobs',
    '@storybook/addon-actions',
    '@storybook/addon-links',
  ],
  webpackFinal: async (config, { configType }) => {
    config.module.rules.push({
      test: /\.scss$/,
      use: ['style-loader', 'css-loader', 'sass-loader'],
      include: path.resolve(__dirname, '../../'),
    });

    config.resolve = {
      ...config.resolve,
      extensions: [...config.resolve.extensions, '.scss'],
      alias: {
        ...config.resolve.alias,
        react: 'preact-compat',
        'react-dom': 'preact-compat',
      },
    };

    return config;
  },
};
