import PropTypes from 'prop-types';
import { h } from 'preact';
import { useEffect } from 'preact/hooks';

const KeyboardShortcuts = ({ shortcuts, ...props }) => {
  useEffect(() => {
    // Return true if element is a form element
    const isFormField = (element) => {
      if (!(element instanceof HTMLElement)) {
        return false;
      }

      const name = element.nodeName.toLowerCase();
      const type = (element.getAttribute("type") || "").toLowerCase();
      return (
        name === "select" ||
        name === "textarea" ||
        (name === "input" && ["submit", "reset", "checkbox", "radio"].indexOf(type) < 0) ||
        element.isContentEditable
      );
    };

    const keyEvent = (e) => {
      if (e.defaultPrevented) return;
      // Get special keys
      const keys = `${e.ctrlKey || e.metaKey ? "ctrl+" : ""}${e.altKey ? "alt+" : ""}${e.shiftKey ? "shift+" : ""}`;
      // If no special keys are pressed and focus is inside a field return
      if (e.target instanceof Node && isFormField(e.target) && !keys) return;
      const shortcut = shortcuts[`${keys}${e.code}`];
      if (shortcut) shortcut(e);
    };

    window.addEventListener("keydown", keyEvent);

    return () => {
      window.removeEventListener("keydown", keyEvent);
    };
  }, [shortcuts]);

  return null;
}

KeyboardShortcuts.defaultProps = {
  shortcuts: {},
};

KeyboardShortcuts.propTypes = {
  shortcuts: PropTypes.object,
};

export default KeyboardShortcuts;
