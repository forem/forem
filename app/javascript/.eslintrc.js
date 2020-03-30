module.exports = {
  parser: 'babel-eslint',
  extends: ['airbnb', 'prettier', 'plugin:jsx-a11y/recommended'],
  parserOptions: {
    ecmaVersion: 2017,
  },
  settings: {
    react: {
      pragma: 'h',
    },
  },
  env: {
    jest: true,
    browser: true,
  },
  plugins: ['import', 'jsx-a11y'],
  rules: {
    'import/no-extraneous-dependencies': [
      'error',
      {
        devDependencies: ['**/*.test.js', '**/*.test.jsx', '**/*.stories.jsx'],
      },
    ],
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
    'import/no-unresolved': [
      'error',
      {
        ignore: ['@crayons'],
      },
    ],
  },
  globals: {
    getCsrfToken: false,
    sendFetch: false,
    InstantClick: false,
    filterXSS: false,
    Pusher: false,
    algoliasearch: false,
    ga: false,
    Honeybadger: false,
  },
};
