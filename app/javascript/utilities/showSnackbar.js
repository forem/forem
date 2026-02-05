/**
 * Cross-context snackbar utility function
 *
 * Handles displaying snackbar messages in different contexts:
 * 1. Regular pages: uses global top.addSnackbarItem
 * 2. Admin/moderator center: uses Stimulus controller with custom events
 * 3. Cross-frame contexts: handles when top is not available
 *
 * @param {string} message - The message to display in the snackbar
 * @param {Object} options - Additional options
 * @param {boolean} options.addCloseButton - Whether to add a close button (default: true)
 */
export function showSnackbar(message, { addCloseButton = true } = {}) {
  // Handle different contexts:
  // 1. Regular pages: addSnackbarItem is assigned to top.addSnackbarItem
  // 2. Admin/moderator center: uses Stimulus controller with custom events
  // 3. Cross-frame contexts: top might not be available

  if (typeof top !== 'undefined' && top.addSnackbarItem) {
    // Global method - comes from app/javascript/Snackbar/Snackbar.jsx
    top.addSnackbarItem({
      message,
      addCloseButton,
    });
  } else if (typeof document !== 'undefined') {
    // Admin context - use custom event for Stimulus controller
    // Note: Admin context typically doesn't use addCloseButton parameter
    document.dispatchEvent(
      new CustomEvent('snackbar:add', {
        detail: { message },
      }),
    );
  } else {
    // Fallback for when neither method is available
    // eslint-disable-next-line no-console
    console.error(message);
  }
}
/**
 * Legacy compatibility function - matches the signature of top.addSnackbarItem
 * @param {Object} options - Options object
 * @param {string} options.message - The message to display
 * @param {boolean} options.addCloseButton - Whether to add a close button
 */
export function addSnackbarItem({ message, addCloseButton = true }) {
  showSnackbar(message, { addCloseButton });
}
