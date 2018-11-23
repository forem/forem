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
};
