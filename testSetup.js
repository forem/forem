/* eslint-env node */
import 'jest-axe/extend-expect';
import './app/assets/javascripts/lib/xss';

global.setImmediate = global.setTimeout;

// TODO: Remove this once https://github.com/nickcolley/jest-axe/issues/147 is fixed.
const { getComputedStyle } = window;
window.getComputedStyle = (elt) => getComputedStyle(elt);

process.on('unhandledRejection', (error) => {
  // Errors thrown here are typically fetch responses that have not been mocked.
  throw error;
});
