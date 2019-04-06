import { h } from 'preact';
import PropTypes from 'prop-types';
import { adjustTimestamp } from './util';
import ErrorMessage from './messages/errorMessage';

const Message = ({
  user,
  userID,
  message,
  color,
  type,
  timestamp,
  profileImageUrl,
  onContentTrigger,
}) => {
  const spanStyle = { color };

  if (type === 'error') {
    return <ErrorMessage message={message} />;
  }

  const messageArea = (
    <span
      className="chatmessagebody__message"
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
  type: PropTypes.string,
  timestamp: PropTypes.string,
  profileImageUrl: PropTypes.string,
  onContentTrigger: PropTypes.func,
};

Message.defaultProps = {
  type: 'normalMessage',
  timestamp: null,
  profileImageUrl: '',
};

export default Message;
