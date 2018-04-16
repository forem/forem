import { h } from 'preact';
import PropTypes from 'prop-types';

/*
 * The prop also contain timeStamp, which is currently not in used
 */

const Message = ({
  user, message, color, hidden,
}) => {
  const spanStyle = { color };
  const linkStyle = { color: 'inherit' };
  const messageStyle = { color: hidden ? 'lightgray' : 'inherit' };

  return (
    <div className="chatmessage">
      <span className="chatmessage__username" style={spanStyle}>
        <a style={linkStyle} href={`/${user}`}>
          {user}
        </a>
      </span>
      <span className="chatmessage__divider">: </span>
      <span className="chatmessage__message" style={messageStyle}>
        {hidden ? '<message removed>' : message}
      </span>
    </div>
  );
};

Message.propTypes = {
  user: PropTypes.string.isRequired,
  color: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  hidden: PropTypes.bool,
};

Message.defaultProps = {
  hidden: false,
};

export default Message;
