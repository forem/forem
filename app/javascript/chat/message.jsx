import { h } from 'preact';
import { useState, useRef, useEffect, useCallback } from 'preact/hooks';
import PropTypes from 'prop-types';
// eslint-disable-next-line import/no-unresolved
import ThreeDotsIcon from 'images/overflow-horizontal.svg';
import { adjustTimestamp } from './util';
import { ErrorMessage } from './messages/errorMessage';
import { Button } from '@crayons';

export const Message = ({
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
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const messageWrapperRef = useRef(null);
  const spanStyle = { color };

  const isCurrentUserMessage = userID === currentUserId;
  const dropdownTriggerId = `dropdown-trigger=${id}`;

  const closeDropdownAndFocusTrigger = useCallback(() => {
    setDropdownOpen(false);
    document.getElementById(dropdownTriggerId)?.focus();
  }, [dropdownTriggerId]);

  useEffect(() => {
    const handleKeyUp = ({ key }) => {
      if (key === 'Escape') {
        // Close the menu and return focus to the button which opened it
        closeDropdownAndFocusTrigger();
      } else if (key === 'Tab') {
        if (!messageWrapperRef.current.contains(document.activeElement)) {
          // Close the menu without stealing focus as the user has tabbed away from the menu options
          setDropdownOpen(false);
        }
      }
    };

    if (dropdownOpen) {
      const firstInteractiveElementId = isCurrentUserMessage
        ? `edit-button-${id}`
        : `report-button-${id}`;
      setDropdownOpen(true);
      document.getElementById(firstInteractiveElementId)?.focus();
      document.addEventListener('keyup', handleKeyUp);
    } else {
      document.removeEventListener('keyup', handleKeyUp);
    }
  }, [
    dropdownOpen,
    id,
    isCurrentUserMessage,
    dropdownTriggerId,
    closeDropdownAndFocusTrigger,
  ]);

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
      <Button
        id={dropdownTriggerId}
        className={`ellipsis__menubutton ${
          dropdownOpen ? 'opacity-1' : 'opacity-0'
        }`}
        size="s"
        variant="ghost"
        onClick={() => {
          dropdownOpen ? closeDropdownAndFocusTrigger() : setDropdownOpen(true);
        }}
        aria-controls={`message-options-dropdown-${id}`}
        aria-haspopup="true"
        aria-expanded={dropdownOpen}
      >
        <img src={ThreeDotsIcon} alt="Message options menu" />
      </Button>

      <div
        id={`message-options-dropdown-${id}`}
        className={`messagebody__dropdownmenu ${dropdownOpen ? '' : 'hidden'}`}
      >
        <Button
          id={`edit-button-${id}`}
          variant="ghost"
          onClick={(_) => onEditMessageTrigger(id)}
        >
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
      <Button
        id={dropdownTriggerId}
        className={`ellipsis__menubutton ${
          dropdownOpen ? 'opacity-1' : 'opacity-0'
        }`}
        size="s"
        variant="ghost"
        onClick={() => {
          dropdownOpen ? closeDropdownAndFocusTrigger() : setDropdownOpen(true);
        }}
        aria-controls={`report-options-dropdown-${id}`}
        aria-haspopup="true"
        aria-expanded={dropdownOpen}
      >
        <img src={ThreeDotsIcon} alt="Report message options" />
      </Button>

      <div
        id={`report-options-dropdown-${id}`}
        className={`messagebody__dropdownmenu report__abuse__button ${
          dropdownOpen ? '' : 'hidden'
        }`}
      >
        <Button
          id={`report-button-${id}`}
          variant="ghost-danger"
          onClick={(_) => onReportMessageTrigger(id)}
        >
          Report Abuse
        </Button>
      </div>
    </div>
  );

  return (
    <div ref={messageWrapperRef} className="chatmessage">
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
