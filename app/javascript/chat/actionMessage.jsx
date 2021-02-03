import { h } from 'preact';
import PropTypes from 'prop-types';
import { adjustTimestamp } from './util';

export const ActionMessage = ({
  user,
  message,
  color,
  timestamp,
  profileImageUrl,
  onContentTrigger,
}) => {
  const spanStyle = { color };

  const messageArea = (
    <span
      className="chatmessagebody__message"
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={{ __html: message }}
    />
  );

  return (
    <div className="chatmessage chatmessage__action ">
      <div className="chatmessage__profilepic">
        <a
          href={`/${user}`}
          target="_blank"
          rel="noopener noreferrer"
          data-content="sidecar-user"
          onClick={onContentTrigger}
        >
          <img
            role="presentation"
            className="chatmessagebody__profileimage"
            src={profileImageUrl}
            alt={`${user} profile`}
            data-content="sidecar-user"
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
            <span
              className="chatmessagebody__username not-dark-theme-text-compatible"
              style={spanStyle}
            >
              <a
                className="chatmessagebody__username--link"
                href={`/${user}`}
                target="_blank"
                rel="noopener noreferrer"
                data-content="sidecar-user"
                onClick={onContentTrigger}
              >
                {user}
              </a>
            </span>
            <span className="chatmessage__timestamp">
              {`${adjustTimestamp(timestamp)}`}
            </span>
          </div>
        </div>
        <div className="chatmessage__bodytext">{messageArea}</div>
      </div>
    </div>
  );
};

ActionMessage.propTypes = {
  user: PropTypes.string.isRequired,
  color: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  timestamp: PropTypes.string,
  profileImageUrl: PropTypes.string,
  onContentTrigger: PropTypes.func.isRequired,
};

ActionMessage.defaultProps = {
  profileImageUrl: '',
  timestamp: null,
};
