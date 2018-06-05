module.exports = {
  collectCoverageFrom: [
    'app/javascript/src/**/*.{js,jsx}',
    '!**/__tests__/**',
    '!**/__stories__/**',
  ],
  moduleNameMapper: {
    '\\.(svg)$': '<rootDir>/empty-module.js',
  },
};
