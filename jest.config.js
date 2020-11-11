// Consistent timezone for testing.
// This does not work on windows, see https://github.com/nodejs/node/issues/4230

/* eslint-env node */

process.env.TZ = 'UTC';

module.exports = {
  setupFilesAfterEnv: ['./testSetup.js'],
  collectCoverageFrom: [
    'bin/*.js',
    'app/javascript/**/*.{js,jsx}',
    // This exclusion avoids running coverage on Barrel files, https://twitter.com/housecor/status/981558704708472832
    '!app/javascript/**/index.js',
    '!app/javascript/packs/**/*.js', // avoids running coverage on webpacker pack files
    '!**/__tests__/**',
    '!**/__stories__/**',
    '!app/javascript/storybook-static/**/*.js',
  ],
  coverageThreshold: {
    global: {
      statements: 41,
      branches: 35,
      functions: 39,
      lines: 41,
    },
  },
  moduleNameMapper: {
    '\\.(svg|png)$': '<rootDir>/empty-module.js',
    '^@crayons(.*)$': '<rootDir>/app/javascript/crayons$1',
    '^@utilities(.*)$': '<rootDir>/app/javascript/utilities$1',
  },
  // The webpack config folder for webpacker is excluded as it has a test.js file that gets
  // picked up by jest if this folder is not excluded causing a false negative of a test suite failing.
  testPathIgnorePatterns: [
    '/node_modules/',
    './config/webpack',
    // Allows developers to add utility modules that jest won't run as test suites.
    '/__tests__/utilities/',
    './app/javascript/storybook-static',
  ],
  watchPlugins: [
    'jest-watch-typeahead/filename',
    'jest-watch-typeahead/testname',
  ],
};
