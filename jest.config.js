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
    // We do not need code coverage on files that are prop types
    // or eslint configuration files.
    '!app/javascript/**/*PropTypes.js',
    '!./**/.eslintrc.js',
    // Ignore Storybook configuration files
    '!app/javascript/.storybook/**/*.{js,jsx}',
  ],
  coverageThreshold: {
    global: {
      statements: 42,
      branches: 38,
      functions: 41,
      lines: 43,
    },
  },
  moduleNameMapper: {
    '\\.(svg|png|css)$': '<rootDir>/empty-module.js',
    '^@crayons(.*)$': '<rootDir>/app/javascript/crayons$1',
    '^@utilities(.*)$': '<rootDir>/app/javascript/utilities$1',
    '^@components(.*)$': '<rootDir>/app/javascript/shared/components$1',
    '^react$': 'preact/compat',
    '^react-dom$': 'preact/compat',
  },
  // The webpack config folder for webpacker is excluded as it has a test.js file that gets
  // picked up by jest if this folder is not excluded causing a false negative of a test suite failing.
  testPathIgnorePatterns: [
    '/node_modules/',
    '<rootDir>/config/webpack',
    // Allows developers to add utility modules that jest won't run as test suites.
    '/__tests__/utilities/',
    '<rootDir>/app/javascript/storybook-static',
    '<rootDir>/cypress',
  ],
  watchPlugins: [
    'jest-watch-typeahead/filename',
    'jest-watch-typeahead/testname',
  ],
};
