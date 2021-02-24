const path = require('path');

module.exports = {
  parser: 'babel-eslint',
  extends: [
    'eslint:recommended',
    'plugin:import/errors',
    'plugin:import/warnings',
    'preact',
    'plugin:jsx-a11y/recommended',
    'prettier',
  ],
  parserOptions: {
    ecmaVersion: 2018,
    ecmaFeatures: {
      jsx: true,
    },
  },
  settings: {
    react: {
      pragma: 'h',
    },
    'import/resolver': {
      webpack: {
        config: {
          resolve: {
            alias: {
              '@crayons': path.join(__dirname, './crayons'),
              '@utilities': path.join(__dirname, './utilities'),
              '@components': path.join(__dirname, './shared/components'),
            },
            extensions: ['.js', '.jsx'],
          },
        },
      },
    },
  },
  env: {
    jest: true,
    browser: true,
  },
  plugins: ['import', 'react', 'jsx-a11y'],
  rules: {
    'import/order': ['error'],
    'import/prefer-default-export': 'off',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'jsx-a11y/label-has-associated-control': [
      'error',
      {
        required: {
          some: ['nesting', 'id'],
        },
      },
    ],
    'react/jsx-no-target-blank': [2, { enforceDynamicLinks: 'always' }],
  },
  overrides: [
    {
      // Turn this rule off for barrel files
      files: ['**/index.js'],
      rules: {
        'import/export': 'off',
      },
    },
  ],
  globals: {
    getCsrfToken: false,
    sendFetch: false,
    InstantClick: false,
    filterXSS: false,
    Pusher: false,
    ga: false,
    Honeybadger: false,
    AndroidBridge: false,
  },
};
