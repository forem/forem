/**
 * Checker that returns true if element is a form element
 *
 * @param {Node} element to be checked
 * @returns {boolean} isFormField
 */
export function isFormField(element) {
  if (element instanceof HTMLElement === false) return false;

  const name = element.nodeName.toLowerCase();
  const type = (element.getAttribute('type') || '').toLowerCase();
  return (
    name === 'select' ||
    name === 'textarea' ||
    (name === 'input' &&
      type !== 'submit' &&
      type !== 'reset' &&
      type !== 'checkbox' &&
      type !== 'radio') ||
    element.isContentEditable
  );
}

/**
 * Function to handle converting key presses to callback functions
 *
 * @param {KeyboardEvent} e Keyboard event
 * @param {string} keys special keys formatted in a string
 * @param {Array} chain array of past keys
 * @param {object} shortcuts object containing callback functions
 * @returns {Array} New chain
 */
export const callShortcut = (e, keys, chain, shortcuts) => {
  const shortcut =
    chain && chain.length > 0
      ? shortcuts[`${chain.join('~')}~${e.code}`]
      : shortcuts[`${keys}${e.code}`] ||
        shortcuts[`${keys}${e.key.toLowerCase()}`];

  if (shortcut) {
    shortcut(e);
    return [];
  }

  if (keys || e.key === 'Shift') {
    return [];
  }

  return [...chain, e.code];
};

const defaultOptions = {
  timeout: 0,
};

/**
 * Pure DOM keyboard shortcut listener that does not require Preact or hooks.
 *
 * @param {object} shortcuts List of keyboard shortcuts/events
 * @param {EventTarget} [eventTarget=window] An event target
 * @param {object} [options={}] Extra options ({ timeout })
 * @returns {Function} Cleanup function to remove the listener
 */
export function initKeyboardShortcuts(
  shortcuts,
  eventTarget = window,
  options = {},
) {
  if (!shortcuts || Object.keys(shortcuts).length === 0) {
    return () => {};
  }

  const timeoutMs =
    typeof options.timeout === 'number'
      ? options.timeout
      : defaultOptions.timeout;

  let keyChain = [];
  let timeoutId = null;

  const clearChainTimeout = () => {
    if (timeoutId !== null) {
      window.clearTimeout(timeoutId);
      timeoutId = null;
    }
  };

  const keyEvent = (e) => {
    if (e.defaultPrevented) return;

    const ctrlKeyEntry = e.ctrlKey ? 'ctrl+' : '';
    const cmdKeyEntry = e.metaKey ? 'cmd+' : '';
    const altKeyEntry = e.altKey ? 'alt+' : '';
    const shiftKeyEntry = e.shiftKey ? 'shift+' : '';

    const keys = `${ctrlKeyEntry}${cmdKeyEntry}${altKeyEntry}${shiftKeyEntry}`;

    if (e.target instanceof Node && isFormField(e.target) && !keys) return;

    clearChainTimeout();
    keyChain = callShortcut(e, keys, keyChain, shortcuts);

    if (keyChain.length > 0) {
      timeoutId = window.setTimeout(() => {
        clearChainTimeout();
        keyChain = [];
      }, timeoutMs);
    }
  };

  eventTarget?.addEventListener('keydown', keyEvent);

  return () => {
    clearChainTimeout();
    eventTarget?.removeEventListener('keydown', keyEvent);
  };
}
