module.exports = {
  parser: 'babel-eslint',
  extends: ['airbnb', 'prettier'],
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
  plugins: ['import', 'babel'],
  rules: {
    'import/no-extraneous-dependencies': [
      'error',
      {
        devDependencies: ['**/*.test.js', '**/*.test.jsx', '**/*.stories.jsx'],
      },
    ],
  },
};
