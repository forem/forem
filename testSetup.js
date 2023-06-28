/* eslint-env jest, node */
import 'jest-axe/extend-expect';
import './app/assets/javascripts/lib/xss';

global.setImmediate = global.setTimeout;

global.ResizeObserver = class ResizeObserver {
  disconnect() {}
  observe() {}
  unobserve() {}
};

// TODO: Remove this once https://github.com/nickcolley/jest-axe/issues/147 is fixed.
const { getComputedStyle } = window;
window.getComputedStyle = (elt) => getComputedStyle(elt);

process.on('unhandledRejection', (error) => {
  // Errors thrown here are typically fetch responses that have not been mocked.
  throw error;
});

expect.extend({
  /**
   * This matcher tests if its subject is neither null nor undefined.
   *
   * Jest's `toBeDefined` only tests if its subject is *strictly* not the value
   * `undefined`, which makes it unsuitable for testing if a value exists as the
   * value might be `null` (which would pass a `toBeDefined` check).
   *
   * @param {any} subject The subject of the matcher
   * @returns
   */
  toExist(subject) {
    if (subject === null || subject === undefined) {
      return {
        pass: false,
        message: () => `Expected ${this.utils.printReceived(subject)} to exist`,
      };
    }

    return {
      pass: true,
      message: () =>
        `Expected ${this.utils.printReceived(subject)} to not exist`,
    };
  },
});
