import { h } from 'preact';
import PropTypes from 'prop-types';
import { adjustTimestamp } from '../util';
import ErrorMessage from './messages/ErrorMessage';

const Message = ({
  user,
  userID,
  message,
  color,
  type,
  messageColor,
  timestamp,
  profileImageUrl,
  onContentTrigger,
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
      dangerouslySetInnerHTML={{ __html: message }}
    />
  );

  return (
    <div className="chatmessage">
      <div className="chatmessage__profilepic">
        <a
          href={`/${user}`}
          target="_blank"
          data-content={`users/${userID}`}
          onClick={onContentTrigger}
        >
          <img
            className="chatmessagebody__profileimage"
            src={profileImageUrl}
            alt={`${user} profile`}
            data-content={`users/${userID}`}
            onClick={onContentTrigger}
          />
        </a>
      </div>
      <div className="chatmessage__body" onClick={onContentTrigger}>
        <span className="chatmessagebody__username" style={spanStyle}>
          <a
            className="chatmessagebody__username--link"
            href={`/${user}`}
            target="_blank"
            data-content={`users/${userID}`}
            onClick={onContentTrigger}
          >
            {user}
          </a>
        </span>
        {timestamp ? (
          <span className="chatmessage__timestamp">
            {`${adjustTimestamp(timestamp)}`}
          </span>
        ) : (
          <span />
        )}
        <div className="chatmessage__bodytext">{messageArea}</div>
      </div>
    </div>
  );
};

Message.propTypes = {
  user: PropTypes.string.isRequired,
  userID: PropTypes.number.isRequired,
  color: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  messageColor: PropTypes.string,
  type: PropTypes.string,
  timestamp: PropTypes.string,
  profileImageUrl: PropTypes.string,
  onContentTrigger: PropTypes.func,
};

Message.defaultProps = {
  type: 'normalMessage',
  timestamp: null,
  profileImageUrl: '',
  messageColor: 'black',
};

export default Message;
