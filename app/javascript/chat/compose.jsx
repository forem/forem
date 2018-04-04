import { h } from 'preact';
import PropTypes from 'prop-types';

const Compose = ({
  handleSubmitOnClick, handleKeyDown,
}) => (
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

Compose.propTypes = {
  handleKeyDown: PropTypes.func.isRequired,
  handleSubmitOnClick: PropTypes.func.isRequired,
};

export default Compose;
