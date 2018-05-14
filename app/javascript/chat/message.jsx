import { h } from 'preact';
import PropTypes from 'prop-types';
import ErrorMessage from './messages/errorMessage';
import Hiddenmessage from './messages/hiddenMessage';

/*
 * The prop also contain timeStamp, which is currently not in used
 *
 */

const Message = ({ user, message, color, type }) => {
  const spanStyle = { color };

  if (type === 'error') {
    return <ErrorMessage message={message} />;
  } else if (type === 'hidden') {
    return <Hiddenmessage user={user} color={color} />;
  }

  const re = new RegExp(`@${window.currentUser.username}`);
  const match = re.exec(message);
  let messageArea;

  if (match) {
    messageArea = (
      <span className="chatmessage__message">
        {message.substr(0, match.index)}
        <span className="chatmessage__currentuser">
          {`@${window.currentUser.username}`}
        </span>
        {message.substr(match.index + match[0].length)}
      </span>
    );
  } else {
    messageArea = <span className="chatmessage__message">{message}</span>;
  }

  return (
    <div className="chatmessage">
      <span className="chatmessage__username" style={spanStyle}>
        <a
          className="chatmessage__username--link"
          href={`/${user}`}
          target="_blank"
        >
          {user}
        </a>
      </span>
      <span className="chatmessage__divider">: </span>
      {messageArea}
    </div>
  );
};

Message.propTypes = {
  user: PropTypes.string.isRequired,
  color: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  type: PropTypes.string,
  // hidden: PropTypes.bool,
  // error: PropTypes.bool,
};

Message.defaultProps = {
  type: 'normalMessage',
};

export default Message;
