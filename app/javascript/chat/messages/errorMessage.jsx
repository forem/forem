import { h } from 'preact';
import PropTypes from 'prop-types';

export const ErrorMessage = ({ message }) => {
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
};

ErrorMessage.propTypes = {
  message: PropTypes.string.isRequired,
};
