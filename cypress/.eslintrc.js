/* eslint-env node */

module.exports = {
  parser: 'babel-eslint',
  extends: [
    'eslint:recommended',
    'plugin:import/errors',
    'plugin:import/warnings',
    'plugin:cypress/recommended',
    'prettier',
  ],
  parserOptions: {
    sourceType: 'module',
  },
  plugins: ['cypress', 'no-only-tests'],
  rules: {
    'import/order': ['error'],
    'import/prefer-default-export': 'off',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'prefer-const': ['error'],
    'no-only-tests/no-only-tests': 'error',
  },
  overrides: [
    {
      // Turn this rule off for barrel files
      files: ['**/index.js'],
      rules: {
        'import/export': 'off',
        'cypress/no-assigning-return-values': 'error',
        'cypress/no-unnecessary-waiting': 'error',
        'cypress/assertion-before-screenshot': 'warn',
        'cypress/no-force': 'warn',
      },
    },
  ],
  env: {
    node: true,
    'cypress/globals': true,
  },
};
