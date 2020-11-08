import { h } from 'preact';
import PropTypes from 'prop-types';

/**
 * Render the error message
 *
 * @param {object} props
 * @param {string} props.message
 *
 * @component
 *
 * @example
 *
 * <ErrorMessage
 *   message={message}
 * />
 */

export default function ErrorMessage({ message }) {
  const errorStyle = { color: 'darksalmon', 'font-size': '13px' };
  return (
    <div className="chatmessage">
      <span className="chatmessage__body" style={errorStyle}>
        Sorry
        <span className="chatmessagebody__currentuser">
          {`@${window.currentUser.username}`}
        </span>
        {` ${message}`}
      </span>
    </div>
  );
}

ErrorMessage.propTypes = {
  message: PropTypes.string.isRequired,
};
