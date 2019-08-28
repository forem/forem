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
  },
  globals: {
    InstantClick: false,
    filterXSS: false,
    Pusher: false,
    algoliasearch: false,
    ga: false,
  },
};
