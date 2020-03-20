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
      use: [
        'style-loader',
        'css-loader',
        {
          loader: 'sass-loader',
          options: {
            // The injected environment variable is so that SASS mixins/functions can handle
            // generating correct CSS for Sprockets or webpack when in Storybook.
            // an example of it's usage can be found in /app/assets/stylesheets/_mixins.scss
            prependData: '$environment: "storybook";',
          },
        },
      ],
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
