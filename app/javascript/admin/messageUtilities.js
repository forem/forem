/**
 * A function to generate an error alert within the /admin/ space.
 *
 * @function displayErrorAlert
 * @param {Object} modalProps Properties of the Error Alert
 * @param {string} modalProps.alertMsg The message displayed within the alert.
 */

export const displayErrorAlert = function (alertMsg) {
  return document.dispatchEvent(
    new CustomEvent('error:generate', {
      detail: { alertMsg },
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
