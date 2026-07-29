/**
 * Cross-context snackbar utility function
 *
 * Handles displaying snackbar messages in different contexts:
 * 1. Regular pages: uses global top.addSnackbarItem if available
 * 2. Admin/moderator center & frame contexts: dispatches custom event 'snackbar:add'
 *    to top.document, parent.document, or local document
 * 3. Fallback: logs message to console
 *
 * @param {string|Object} message - The message to display in the snackbar
 * @param {Object} [options] - Additional options
 * @param {boolean} [options.addCloseButton=true] - Whether to add a close button
 */
export function showSnackbar(message, { addCloseButton = true } = {}) {
  const formattedMessage =
    typeof message === 'object' && message !== null
      ? message.message || JSON.stringify(message)
      : String(message ?? '');

  // 1. Try top.addSnackbarItem safely (handles cross-origin SecurityError)
  try {
    if (typeof top !== 'undefined' && typeof top.addSnackbarItem === 'function') {
      top.addSnackbarItem({
        message: formattedMessage,
        addCloseButton,
      });
      return;
    }
  } catch (e) {
    // Access to top frame blocked by cross-origin security policy
  }

  // 2. Cross-frame event dispatching (try top.document, parent.document, then document)
  const targetDoc = getTargetDocument();
  if (targetDoc) {
    targetDoc.dispatchEvent(
      new CustomEvent('snackbar:add', {
        detail: {
          message: formattedMessage,
          addCloseButton,
        },
      }),
    );
    return;
  }

  // 3. Fallback when no document is available
  // eslint-disable-next-line no-console
  console.error(formattedMessage);
}

function getTargetDocument() {
  try {
    if (typeof top !== 'undefined' && top && top.document) {
      return top.document;
    }
  } catch (e) {
    // Cross-origin top access failed
  }

  try {
    if (typeof window !== 'undefined' && window.parent && window.parent.document) {
      return window.parent.document;
    }
  } catch (e) {
    // Cross-origin parent access failed
  }

  if (typeof document !== 'undefined') {
    return document;
  }

  return null;
}

/**
 * Legacy compatibility function - matches the signature of top.addSnackbarItem
 * @param {Object} options - Options object
 * @param {string} options.message - The message to display
 * @param {boolean} [options.addCloseButton=true] - Whether to add a close button
 */
export function addSnackbarItem({ message, addCloseButton = true } = {}) {
  showSnackbar(message, { addCloseButton });
}

