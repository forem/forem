/* eslint-env node */

module.exports = {
  parser: 'babel-eslint',
  extends: [
    'plugin:cypress/recommended',
    'eslint:recommended',
    'plugin:import/errors',
    'plugin:import/warnings',
    'preact',
    'prettier',
  ],
  parserOptions: {
    ecmaVersion: 'es2021',
  },
  plugins: ['cypress'],
  rules: {
    'import/order': ['error'],
    'import/prefer-default-export': 'off',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
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
    'cypress/globals': true,
  },
};
