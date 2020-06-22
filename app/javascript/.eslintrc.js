const path = require('path');

module.exports = {
  parser: 'babel-eslint',
  extends: [
    'eslint:recommended',
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
