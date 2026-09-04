/* eslint-env node */

module.exports = {
  extends: ['eslint:recommended', 'prettier'],
  parserOptions: {
    ecmaVersion: 2018,
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
    applyColorMode: false,
    watchColorModeChanges: false,
    getCsrfToken: false,
    sendFetch: false,
    preventDefaultAction: false,
    userData: false,
    ga: false, // Google Analytics
    gtag: false, // Google Analytics 4
    handleOptimisticButtRender: false,
    handleFollowButtPress: false,
    browserStoreCache: false,
    globalFeatureFlagEnabled: false,
    initializeBaseUserData: false,
    initializeBillboardVisibility: false,
    initializeFavoritedMarkers: false,
    initializeReadingListIcons: false,
    ActiveXObject: false,
    AndroidBridge: false,
  },
};
