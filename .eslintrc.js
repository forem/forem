module.exports = {
  extends: ['airbnb-base/legacy', 'prettier'],
  parserOptions: {
    ecmaVersion: 6,
  },
  env: {
    browser: true,
  },
  plugins: ['ignore-erb'],
};
