import { h } from 'preact';
import PropTypes from 'prop-types';

const HiddenMessage = ({ user, color, profileImageUrl }) => {
  const spanStyle = { color };
  return (
    <div className="chatmessage">
      <div className="chatmessage__body">
        <a href={`/${user}`} target="_blank">
          <img
            className="chatmessagebody__profileimage"
            src={profileImageUrl}
            alt={`${user} profile`}
          />
        </a>
        <span className="chatmessagebody__username" style={spanStyle}>
          <a
            className="chatmessagebody__username--link"
            href={`/${user}`}
            target="_blank"
          >
            {user}
          </a>
        </span>
        <span className="chatmessagebody__divider">: </span>
        <span
          className="chatmessagebody__message"
          style={{ color: 'lightgray' }}
        >
          {'<message removed>'}
        </span>
      </div>
    </div>
  );
};

HiddenMessage.propTypes = {
  user: PropTypes.string.isRequired,
  color: PropTypes.string.isRequired,
  profileImageUrl: PropTypes.string.isRequired,
};

export default HiddenMessage;
