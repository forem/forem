import { useEffect } from "preact/hooks";
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
  useEffect(() => {
    if (!shortcuts || Object.keys(shortcuts).length === 0) return;

    const keyEvent = (e) => {
      if (e.defaultPrevented) return;

      // Get special keys
      const keys = `${e.ctrlKey || e.metaKey ? "ctrl+" : ""}${e.altKey ? "alt+" : ""}${e.shiftKey ? "shift+" : ""}`;
      
      // If no special keys are pressed and focus is inside a field return
      if (e.target instanceof Node && isFormField(e.target) && !keys) return;
      
      const shortcut = shortcuts[`${keys}${e.code}`] || shortcuts[`${keys}${e.key.toLowerCase()}`];
      if (shortcut) shortcut(e);
    };

    eventTarget.addEventListener("keydown", keyEvent);

    return () => {
      eventTarget.removeEventListener("keydown", keyEvent);
    };
  }, [shortcuts, eventTarget]);
}

/**
 * compoent that can be added to a component to listen
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
