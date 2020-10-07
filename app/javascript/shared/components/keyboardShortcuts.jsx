import PropTypes from 'prop-types';
import { h } from 'preact';
import { useEffect } from 'preact/hooks';

const KeyboardShortcuts = ({ shortcuts, ...props }) => {
  useEffect(() => {
    const checkShortcut = (e, keys) => {
      if (!keys) return;
      const shortcut = shortcuts[`${keys}${e.code}`];
      if (shortcut) shortcut(e);
    };

    const keyEvent = (e) => {
      checkShortcut(
        e,
        `${(e.ctrlKey || e.metaKey) ? 'ctrl+' : ''}${e.altKey ? 'alt+' : ''}${e.shiftKey ? 'shift+' : ''}`
      );
    };

    window.addEventListener('keydown', keyEvent);

    return () => {
      window.removeEventListener('keydown', keyEvent);
    }
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
