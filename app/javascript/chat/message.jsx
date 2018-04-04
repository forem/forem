import { h } from 'preact';
import PropTypes from 'prop-types';

/*
 * The prop also contain timeStamp, which is currently not in used
 */

const Message = ({
  user, message, color,
}) => {
  const spanStyle = { color };
  return (
    <div className="chatmessage">
      <span className="chatmessage__username" style={spanStyle}>{ user }</span>
      <span className="chatmessage__divider">: </span>
      <span className="chatmessage__message">{ message } </span>
    </div>
  );
};

Message.propTypes = {
  user: PropTypes.string.isRequired,
  color: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
};

export default Message;
