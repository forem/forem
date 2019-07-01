module.exports = {
  extends: ['airbnb-base/legacy', 'prettier'],
  parserOptions: {
    ecmaVersion: 2017,
  },
  env: {
    browser: true,
  },
  plugins: ['ignore-erb'],
  rules: {
    'no-unused-vars': 'off',
    'vars-on-top': 'off',
  },
  globals: {
    getCsrfToken: false,
    sendFetch: false,
  },
};
