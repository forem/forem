import { h } from 'preact';
import PropTypes from 'prop-types';
import { adjustTimestamp } from './util';
import ErrorMessage from './messages/errorMessage';
import Hiddenmessage from './messages/hiddenMessage';

const Message = ({
  user,
  message,
  color,
  type,
  timestamp,
  profileImageUrl,
}) => {
  const spanStyle = { color };

  if (type === 'error') {
    return <ErrorMessage message={message} />;
  } else if (type === 'hidden') {
    return (
      <Hiddenmessage
        user={user}
        color={color}
        profileImageUrl={profileImageUrl}
      />
    );
  }

  const re = new RegExp(`@${window.currentUser.username}`);
  const match = re.exec(message);
  let messageArea;

  if (match) {
    messageArea = (
      <span className="chatmessagebody__message">
        {message.substr(0, match.index)}
        <span className="chatmessagebody__currentuser">
          {`@${window.currentUser.username}`}
        </span>
        {message.substr(match.index + match[0].length)}
      </span>
    );
  } else {
    messageArea = <span className="chatmessagebody__message">{message}</span>;
  }

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
  type: PropTypes.string,
  timestamp: PropTypes.string,
  profileImageUrl: PropTypes.string,
};

Message.defaultProps = {
  type: 'normalMessage',
  timestamp: null,
  profileImageUrl: '',
};

export default Message;
