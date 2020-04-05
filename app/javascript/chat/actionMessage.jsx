import { h } from 'preact';
import PropTypes from 'prop-types';

const ActionMessage = ({
  user,
  message,
  profileImageUrl,
  onContentTrigger,
}) => {
  const messageArea = (
    <span
      className="chatmessagebody__message"
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={{ __html: message }}
    />
  );

  return (
    <div className="chatmessage chatmessage__action ">
      <div className="action__message">
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
          className="chatmessage__bodytext"
          role="presentation"
          onClick={onContentTrigger}
        >
          {messageArea}
        </div>
      </div>
    </div>
  );
};

ActionMessage.propTypes = {
  user: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  profileImageUrl: PropTypes.string,
  onContentTrigger: PropTypes.func.isRequired,
};

ActionMessage.defaultProps = {
  profileImageUrl: '',
};

export default ActionMessage;
