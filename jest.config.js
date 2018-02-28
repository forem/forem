module.exports = {
  collectCoverageFrom: [
    'app/javascript/src/**/*.{js,jsx}',
    '!**/__tests__/**'
  ],
  moduleNameMapper: {
    '\\.(svg)$': '<rootDir>/empty-module.js'
  }
};
