module.exports = {
  extends: ['airbnb-base/legacy', 'prettier'],
  parserOptions: {
    ecmaVersion: 5,
  },
  env: {
    browser: true,
  },
  plugins: ['ignore-erb'],
};
