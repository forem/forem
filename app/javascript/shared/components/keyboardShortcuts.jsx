import PropTypes from 'prop-types';
import { h } from 'preact';
import { useEffect } from 'preact/hooks';

const KeyboardShortcuts = ({ shortcuts, ...props }) => {
  useEffect(() => {
    const checkShortcut = (e, keys) => {
      if (keys.length <= 0) return;
      let shortcut = shortcuts;
      for (let key of keys) {
        if (!shortcut[key]) return;
        shortcut = shortcut[key];
      }
      if (shortcut[e.code]) shortcut[e.code](e);
    };

    const keyEvent = (e) => {
      const modifierKeys = [];
      if (e.ctrlKey || e.metaKey) modifierKeys.push('ctrl');
      if (e.altKey) modifierKeys.push('alt');
      if (e.shiftKey) modifierKeys.push('shift');
      checkShortcut(e, modifierKeys);
    }

    window.addEventListener('keydown', keyEvent);

    return () => {
      window.removeEventListener('keydown', keyEvent);
    }
  }, [shortcuts])

  return null;
}

KeyboardShortcuts.defaultProps = {
  shortcuts: {},
};

KeyboardShortcuts.propTypes = {
  shortcuts: PropTypes.object,
};

export default KeyboardShortcuts;
