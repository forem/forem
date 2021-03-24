import { useState, useEffect, useCallback } from 'preact/hooks';
import PropTypes from 'prop-types';

/**
 * Checker that return true if element is a form element
 *
 * @param {node} element to be checked
 *
 * @returns {boolean} isFormField
 */
function isFormField(element) {
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

// Default options to be used if null
const defaultOptions = {
  timeout: 0, // The default is zero as we want no delays between keystrokes by default.
};

/**
 * hook that can be added to a component to listen
 * for keyboard presses
 *
 * @example
 * const shortcuts = {
 *   "ctrl+alt+KeyG": (e) => {
 *     e.preventDefault();
 *     alert("Control Alt G has been pressed");
 *   },
 *   "KeyG~KeyH": (e) => {
 *     e.preventDefault();
 *     alert("G has been pressed quickly followed by H");
 *   },
 *   "?": (e) => {
 *     setIsHelpVisible(true);
 *   }
 * }
 *
 * useKeyboardShortcuts(shortcuts, someElementOrWindowObject, {timeout: 1500});
 *
 * @param {object} shortcuts List of keyboard shortcuts/event
 * @param {EventTarget} [eventTarget=window] An event target.
 * @param {object} [options = {}] An object for extra options
 *
 */
export function useKeyboardShortcuts(
  shortcuts,
  eventTarget = window,
  options = {},
) {
  const [keyChain, setKeyChain] = useState([]);
  const [keyChainQueue, setKeyChainQueue] = useState(null);
  const [mergedOptions, setMergedOptions] = useState({
    ...defaultOptions,
    ...options,
  });

  // Work out the correct shortcut for the key press
  const callShortcut = useCallback(
    (e, keys) => {
      let shortcut;
      if (keyChain.length > 0) {
        shortcut = shortcuts[`${keyChain.join('~')}~${e.code}`];
      } else {
        shortcut =
          shortcuts[`${keys}${e.code}`] ||
          shortcuts[`${keys}${e.key.toLowerCase()}`];
      }

      // if a valid shortcut is found call it and reset the chain
      if (shortcut) {
        shortcut(e);
        setKeyChain([]);
      }
    },
    [shortcuts, keyChain],
  );

  // update mergedOptions if options prop changes
  useEffect(() => {
    const newOptions = {};
    if (typeof options.timeout === 'number')
      newOptions.timeout = options.timeout;
    setMergedOptions({ ...defaultOptions, ...newOptions });
  }, [options.timeout]);

  // Set up key chains
  useEffect(() => {
    if (!keyChainQueue && keyChain.length === 0) return;

    const timeout = window.setTimeout(() => {
      clearTimeout(timeout);
      setKeyChain([]);
    }, mergedOptions.timeout);

    if (keyChainQueue) {
      setKeyChain([...keyChain, keyChainQueue]);
      setKeyChainQueue(null);
    }

    return () => clearTimeout(timeout);
  }, [keyChain, keyChainQueue, mergedOptions.timeout]);

  // set up event listeners
  useEffect(() => {
    if (!shortcuts || Object.keys(shortcuts).length === 0) return;

    const keyEvent = (e) => {
      if (e.defaultPrevented) return;

      // Get special keys
      const keys = `${e.ctrlKey || e.metaKey ? 'ctrl+' : ''}${
        e.altKey ? 'alt+' : ''
      }${(e.ctrlKey || e.metaKey || e.altKey) && e.shiftKey ? 'shift+' : ''}`;

      // If no special keys, except shift, are pressed and focus is inside a field return
      if (e.target instanceof Node && isFormField(e.target) && !keys) return;

      // If a special key is pressed reset the key chain else add to the chain
      if (keys) {
        setKeyChain([]);
      } else {
        setKeyChainQueue(e.code);
      }

      callShortcut(e, keys);
    };

    eventTarget.addEventListener('keydown', keyEvent);

    return () => eventTarget.removeEventListener('keydown', keyEvent);
  }, [shortcuts, eventTarget, callShortcut]);
}

/**
 * A component that can be added to a component to listen
 * for keyboard presses using the useKeyboardShortcuts hook
 *
 * @example
 * const shortcuts = {
 *   "ctrl+alt+KeyG": (e) => {
 *     e.preventDefault();
 *     alert("Control Alt G has been pressed")
 *   }
 * }
 *
 * <KeyboardShortcuts shortcuts={shortcuts} />
 * <KeyboardShortcuts shortcuts={shortcuts} eventTarget={ref.current} />
 *
 * @param {object} shortcuts List of keyboard shortcuts/event
 * @param {EventTarget} [eventTarget=window] An event target.
 * @param {object} [options = {}] An object for extra options
 *
 */
export function KeyboardShortcuts({ shortcuts, eventTarget, options }) {
  useKeyboardShortcuts(shortcuts, eventTarget, options);

  return null;
}

KeyboardShortcuts.propTypes = {
  shortcuts: PropTypes.object.isRequired,
  options: PropTypes.shape({
    timeout: PropTypes.number,
  }),
  eventTarget: PropTypes.instanceOf(Element),
};

KeyboardShortcuts.defaultProps = {
  shortcuts: {},
  options: {},
  eventTarget: window,
};
