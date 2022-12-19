const path = require('path');

module.exports = {
  parser: '@babel/eslint-parser',
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
              '@images': path.join(__dirname, '../assets/images'),
              '@admin': path.join(__dirname, './admin'),
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
    'no-var': 'error',
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
    'jsx-a11y/no-onchange': 'off',
    'prefer-const': ['error'],
    'prefer-destructuring': ['warn', { object: true, array: false }],
    'react/jsx-curly-brace-presence': [
      'error',
      { props: 'never', children: 'never' },
    ],
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
    ga: false,
    gtag: false,
    Honeybadger: false,
    AndroidBridge: false,
  },
};
