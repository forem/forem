import { useState, useEffect, useCallback } from "preact/hooks";
import PropTypes from 'prop-types';
import { h } from 'preact';

/**
 * Checker that return true if element is a form element
 *
 * @param {node} element to be checked
 *
 * @returns {boolean} isFormField
 */
function isFormField(element) {
  if ((element instanceof HTMLElement) === false) return false;

  const name = element.nodeName.toLowerCase();
  const type = (element.getAttribute("type") || "").toLowerCase();
  return (
    name === "select" ||
    name === "textarea" ||
    (name === "input" && ["submit", "reset", "checkbox", "radio"].indexOf(type) < 0) ||
    element.isContentEditable
  );
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
 *   "?": (e) => {
 *     setIsHelpVisible(true);
 *   }
 * }
 *
 * useKeyboardShortcuts(shortcuts, someElementOrWindowObject);
 *
 * @param {object} shortcuts List of keyboard shortcuts/event
 * @param {EventTarget} [eventTarget=window] An event target.
 *
 */
export function useKeyboardShortcuts(shortcuts, eventTarget = window) {
  const [keyChain, setKeyChain] = useState([]);
  const [keyChainQueue, setKeyChainQueue] = useState([]);

  // Work out the correct shortcut for the key press
  const callShortcut = useCallback((e, keys) => {
    let shortcut;
    if (keyChain.length > 0) {
      shortcut = shortcuts[`${keyChain.join("~")}~${e.code}`];
    } else {
      shortcut = shortcuts[`${keys}${e.code}`] || shortcuts[`${keys}${e.key.toLowerCase()}`];
    }

    // if a valid shortcut is found call it and reset the chain
    if (shortcut) {
      shortcut(e);
      setKeyChain([]);
    }
  }, [shortcuts, keyChain]);

  // Set up key chains
  useEffect(() => {
    if (!keyChainQueue && keyChain.length === 0) return;
    let timeout;

    timeout = window.setTimeout(() => {
      clearTimeout(timeout);
      setKeyChain([]);
    }, 500);

    if (keyChainQueue) {
      setKeyChain([...keyChain, keyChainQueue]);
      setKeyChainQueue(null);
    }

    return () => clearTimeout(timeout);
  }, [keyChain, keyChainQueue]);

  // set up event listeners
  useEffect(() => {
    if (!shortcuts || Object.keys(shortcuts).length === 0) return;

    const keyEvent = (e) => {
      if (e.defaultPrevented) return;

      // Get special keys
      const keys = `${e.ctrlKey || e.metaKey ? "ctrl+" : ""}${e.altKey ? "alt+" : ""}${e.shiftKey ? "shift+" : ""}`;

      // If no special keys, except shift, are pressed and focus is inside a field return
      if (e.target instanceof Node && isFormField(e.target) && (!keys || keys === "shift+")) return;
      
      // If a special key is pressed reset the key chain else add to the chain
      if (keys) {
        setKeyChain([]);
      } else {
        setKeyChainQueue(e.code);
      }

      callShortcut(e, keys);
    };

    eventTarget.addEventListener("keydown", keyEvent);

    return () => eventTarget.removeEventListener("keydown", keyEvent);
  }, [shortcuts, eventTarget, callShortcut]);
}

/**
 * component that can be added to a component to listen
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
 *
 */
export function KeyboardShortcuts({ shortcuts, eventTarget }) {
  useKeyboardShortcuts(shortcuts, eventTarget);

  return null;
}

KeyboardShortcuts.propTypes = {
  shortcuts: PropTypes.object.isRequired,
  eventTarget: PropTypes.instanceOf(Element)
}

KeyboardShortcuts.defaultProps = {
  shortcuts: {},
  eventTarget: window
}
