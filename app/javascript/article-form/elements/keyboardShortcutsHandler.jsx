import { Component } from 'preact';
import PropTypes from 'prop-types';

class KeyboardShortcutsHandler extends Component {
  componentDidMount() {
    document.addEventListener('keydown', this.handleKeyDown());
  }

  componentWillUnmount() {
    document.removeEventListener('keydown', this.globalKeysListener);
  }

  handleKeyDown = () => {
    this.globalKeysListener = event => {
      const controlOrCommandKey = event.ctrlKey || event.metaKey;
      if (
        controlOrCommandKey &&
        event.shiftKey &&
        event.key.toUpperCase() === 'P'
      ) {
        const { togglePreview } = this.props;
        togglePreview(event);
      }
    };

    return this.globalKeysListener;
  };

  render() {
    return null;
  }
}

KeyboardShortcutsHandler.propTypes = {
  togglePreview: PropTypes.func.isRequired,
};

export default KeyboardShortcutsHandler;
