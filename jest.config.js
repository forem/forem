module.exports = {
  collectCoverageFrom: [
    'app/javascript/src/**/*.{js,jsx}',
    // This exclusion avoids running coverage on Barrel files, https://twitter.com/housecor/status/981558704708472832
    '!app/javascript/src/**/components/**/index.js',
    '!**/__tests__/**',
    '!**/__stories__/**',
  ],
  moduleNameMapper: {
    '\\.(svg|png)$': '<rootDir>/empty-module.js',
  },
  snapshotSerializers: ['preact-render-spy/snapshot'],
  // The webpack config folder for webpacker is excluded as it has a test.js file that gets
  // picked up by jest if this folder is not excluded causing a false negative of a test suite failing.
  testPathIgnorePatterns: [
    '/node_modules/',
    './config/webpack',
    // Allows developers to add utility modules that jest won't run as test suites.
    '/__tests__/utilities/',
  ],
};
