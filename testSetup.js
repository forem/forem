/* eslint-env node */
import 'jest-axe/extend-expect';
import './app/assets/javascripts/lib/xss';

global.setImmediate = global.setTimeout;

process.on('unhandledRejection', (error) => {
  // Errors thrown here are typically fetch responses that have not been mocked.
  throw error;
});
