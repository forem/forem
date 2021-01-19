import { h } from 'preact';
import PropTypes from 'prop-types';
// eslint-disable-next-line import/no-unresolved
import ThreeDotsIcon from 'images/overflow-horizontal.svg';
import { adjustTimestamp } from './util';
import ErrorMessage from './messages/errorMessage';
import { Button } from '@crayons';

const Message = ({
  currentUserId,
  id,
  user,
  userID,
  message,
  color,
  type,
  editedAt,
  timestamp,
  profileImageUrl,
  onContentTrigger,
  onDeleteMessageTrigger,
  onReportMessageTrigger,
  onEditMessageTrigger,
}) => {
  const spanStyle = { color };

  if (type === 'error') {
    return <ErrorMessage message={message} />;
  }

  const MessageArea = () => {
    if (userID === currentUserId) {
      message = message.replace(`@${user}`, `<mark>@${user}</mark>`);
    }

    return (
      <span
        className="chatmessagebody__message"
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{ __html: message }}
      />
    );
  };

  const dropdown = (
    <div className="message__actions">
      <span className="ellipsis__menubutton">
        <img src={ThreeDotsIcon} alt="dropdown menu icon" />
      </span>

      <div className="messagebody__dropdownmenu">
        <Button variant="ghost" onClick={(_) => onEditMessageTrigger(id)}>
          Edit
        </Button>
        <Button
          variant="ghost-danger"
          onClick={(_) => onDeleteMessageTrigger(id)}
        >
          Delete
        </Button>
      </div>
    </div>
  );
  const dropdownReport = (
    <div className="message__actions">
      <span className="ellipsis__menubutton">
        <img src={ThreeDotsIcon} alt="message actions" />
      </span>

      <div className="messagebody__dropdownmenu report__abuse__button">
        <Button
          variant="ghost-danger"
          onClick={(_) => onReportMessageTrigger(id)}
        >
          Report Abuse
        </Button>
      </div>
    </div>
  );

  return (
    <div className="chatmessage">
      <div className="chatmessage__profilepic">
        <a
          href={`/${user}`}
          target="_blank"
          rel="noopener noreferrer"
          data-content="sidecar-user"
          onClick={onContentTrigger}
          aria-label="View User Profile"
        >
          <img
            className="chatmessagebody__profileimage"
            src={profileImageUrl}
            alt={`${user} profile`}
            data-content="sidecar-user"
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
            {editedAt ? (
              <span className="chatmessage__timestamp edited_message">
                {`${adjustTimestamp(editedAt)}`}
                <i> (edited)</i>
              </span>
            ) : (
              ' '
            )}

            {timestamp && !editedAt ? (
              <span className="chatmessage__timestamp">
                {`${adjustTimestamp(timestamp)}`}
              </span>
            ) : (
              ' '
            )}
          </div>
          {userID === currentUserId ? dropdown : dropdownReport}
        </div>
        <div className="chatmessage__bodytext">
          <MessageArea />
        </div>
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
  editedAt: PropTypes.number.isRequired,
  profileImageUrl: PropTypes.string,
  onContentTrigger: PropTypes.func.isRequired,
  onDeleteMessageTrigger: PropTypes.func.isRequired,
  onEditMessageTrigger: PropTypes.func.isRequired,
  onReportMessageTrigger: PropTypes.func.isRequired,
};

Message.defaultProps = {
  type: 'normalMessage',
  timestamp: null,
  profileImageUrl: '',
};

export default Message;
