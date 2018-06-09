import { h } from 'preact';
import PropTypes from 'prop-types';
import { adjustTimestamp } from './util';
import ErrorMessage from './messages/errorMessage';

const Message = ({
  user,
  message,
  color,
  type,
  messageColor,
  timestamp,
  profileImageUrl,
}) => {
  const spanStyle = { color };
  const messageStyle = { color: messageColor };

  if (type === 'error') {
    return <ErrorMessage message={message} />;
  }

  const messageArea = (
      <span
        className="chatmessagebody__message"
        style={messageStyle}
        dangerouslySetInnerHTML={{__html: message}}
      ></span>
    );
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
        {messageArea}
      </div>
      {timestamp ? (
        <span className="chatmessage__timestamp">
          {`${adjustTimestamp(timestamp)}`}
        </span>
      ) : (
        <span />
      )}
    </div>
  );
};

Message.propTypes = {
  user: PropTypes.string.isRequired,
  color: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  messageColor: PropTypes.string,
  type: PropTypes.string,
  timestamp: PropTypes.string,
  profileImageUrl: PropTypes.string,
};

Message.defaultProps = {
  type: 'normalMessage',
  timestamp: null,
  profileImageUrl: '',
  messageColor: 'black',
};

export default Message;
