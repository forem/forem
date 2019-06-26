import { Component } from 'preact';
import PropTypes from 'prop-types';

class HotkeyLinstener extends Component {
  componentDidMount() {
    document.addEventListener('keydown', this.handleKeyDowm());
  }

  componentWillUnmount() {
    document.removeEventListener('keydown', this.globalKeysListener);
  }

  handleKeyDowm = () => {
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

HotkeyLinstener.propTypes = {
  togglePreview: PropTypes.func.isRequired,
};

export default HotkeyLinstener;
