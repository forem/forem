import { h } from 'preact';
import PropTypes from 'prop-types';

const HiddenMessage = ({ user, color }) => {
  const spanStyle = { color };
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
      <span className="chatmessage__message" style={{ color: 'lightgray' }}>
        {'<message removed>'}
      </span>
    </div>
  );
};

HiddenMessage.propTypes = {
  user: PropTypes.string.isRequired,
  color: PropTypes.string.isRequired,
};

export default HiddenMessage;
