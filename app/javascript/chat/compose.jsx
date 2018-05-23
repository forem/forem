import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export default class Chat extends Component {
  static propTypes = {
    handleKeyDown: PropTypes.func.isRequired,
    handleSubmitOnClick: PropTypes.func.isRequired,
  };

  shouldComponentUpdate() {
    return false;
  }

  render() {
    const { handleSubmitOnClick, handleKeyDown } = this.props;

    return (
      <div className="messagecomposer">
        <textarea
          className="messagecomposer__input"
          id="messageform"
          placeholder="Message goes here"
          onKeyDown={handleKeyDown}
        />
        <button
          className="messagecomposer__submit"
          onClick={handleSubmitOnClick}
        >
          SEND
        </button>
      </div>
    );
  }
}
