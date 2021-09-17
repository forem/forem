/**
 * A function to generate an error alert within the /admin/ space.
 *
 * @function errorAlert
 * @param {Object} modalProps Properties of the Error Alert
 * @param {string} modalProps.errMsg The error message displayed within the alert.
 */

export const displayErrorAlert = function (errMsg) {
  return document.dispatchEvent(
    new CustomEvent('error:generate', {
      detail: { errMsg },
    }),
  );
};

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
