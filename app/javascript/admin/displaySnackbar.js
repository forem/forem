/**
 * A function to generate a snackbar within the /admin/ space.
 *
 * @function displaySnackbar
 * @param {Object} modalProps Properties of the Snackbar
 * @param {string} modalProps.message The message displayed within the snackbar.
 */

export const displaySnackbar = function (message) {
  return document.dispatchEvent(
    new CustomEvent('snackbar:add', {
      detail: { message },
    }),
  );
};
