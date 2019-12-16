import { h } from 'preact';
import PropTypes from 'prop-types';
import { adjustTimestamp } from './util';
import ErrorMessage from './messages/errorMessage';

const Message = ({
  currentUserId,
  id,
  user,
  userID,
  message,
  color,
  type,
  timestamp,
  profileImageUrl,
  onContentTrigger,
  onDeleteMessageTrigger,
}) => {
  const spanStyle = { color };

  if (type === 'error') {
    return <ErrorMessage message={message} />;
  }

  const messageArea = (
    <span
      className="chatmessagebody__message"
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={{ __html: message }}
    />
  );

  return (
    <div className="chatmessage">
      <div className="chatmessage__profilepic">
        <a
          href={`/${user}`}
          target="_blank"
          rel="noopener noreferrer"
          data-content={`users/${userID}`}
          onClick={onContentTrigger}
        >
          <img
            role="presentation"
            className="chatmessagebody__profileimage"
            src={profileImageUrl}
            alt={`${user} profile`}
            data-content={`users/${userID}`}
            onClick={onContentTrigger}
          />
        </a>
      </div>
      <div
        role="presentation"
        className="chatmessage__body"
        onClick={onContentTrigger}
      >
        <div className="message__info__actions">
          <div className="message__info">
            <span className="chatmessagebody__username" style={spanStyle}>
              <a
                className="chatmessagebody__username--link"
                href={`/${user}`}
                target="_blank"
                rel="noopener noreferrer"
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
          </div>
          {userID === currentUserId ? (
            <div className="message__actions">
              <span
                role="button"
                data-content={id}
                onClick={onDeleteMessageTrigger}
                tabIndex="0"
                onKeyUp={e => {
                  if (e.keyCode === 13) onDeleteMessageTrigger();
                }}
              >
                Delete
              </span>
            </div>
          ) : (
            ' '
          )}
        </div>
        <div className="chatmessage__bodytext">{messageArea}</div>
      </div>
    </div>
  );
};

Message.propTypes = {
  currentUserId: PropTypes.number.isRequired,
  id: PropTypes.number.isRequired,
  user: PropTypes.string.isRequired,
  userID: PropTypes.number.isRequired,
  color: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  type: PropTypes.string,
  timestamp: PropTypes.string,
  profileImageUrl: PropTypes.string,
  onContentTrigger: PropTypes.func.isRequired,
  onDeleteMessageTrigger: PropTypes.func.isRequired,
};

Message.defaultProps = {
  type: 'normalMessage',
  timestamp: null,
  profileImageUrl: '',
};

export default Message;
