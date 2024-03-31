// ***********************************************************
// This example support/index.js is processed and
// loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// You can change the location of this file or turn off
// automatically serving support files with the
// 'supportFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/configuration
// ***********************************************************

// For Testing Library APIs https://github.com/testing-library/cypress-testing-library
import '@cypress/code-coverage/support';
import '@testing-library/cypress/add-commands';
import 'cypress-file-upload';
import 'cypress-failed-log';

// Custom assertions
import './assertions';

// Import commands.js using ES2015 syntax:
import './commands';

// Helper for retriable actions (e.g. to account for asynchronously attached event listeners) https://github.com/NicholasBoll/cypress-pipe
import 'cypress-pipe';

// Alternatively you can use CommonJS syntax:
// require('./commands')
