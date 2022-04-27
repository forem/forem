/**
 * When running in Jest, we globally mock the tabbable library used by focus-trap.
 * This is to work around limitations testing components which use a focus trap in JSDom.
 * See: https://github.com/focus-trap/tabbable#testing-in-jsdom
 */

const lib = jest.requireActual('tabbable');

const tabbable = {
  ...lib,
  tabbable: (node, options) =>
    lib.tabbable(node, { ...options, displayCheck: 'none' }),
  focusable: (node, options) =>
    lib.focusable(node, { ...options, displayCheck: 'none' }),
  isFocusable: (node, options) =>
    lib.isFocusable(node, { ...options, displayCheck: 'none' }),
  isTabbable: (node, options) =>
    lib.isTabbable(node, { ...options, displayCheck: 'none' }),
};

module.exports = tabbable;
