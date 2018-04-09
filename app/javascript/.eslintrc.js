module.exports = {
  extends: ['airbnb', 'prettier'],
  parserOptions: {
    ecmaVersion: 6,
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
  plugins: ['import'],
  rules: {
    'import/no-extraneous-dependencies': [
      'error',
      {
        devDependencies: ['**/*.test.js', '**/*.test.jsx', '**/*.stories.jsx'],
      },
    ],
  },
};
