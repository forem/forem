import { h } from 'preact';
import PropTypes from 'prop-types';
import ActionMessage from '../actionMessage';
import Message from '../message';
import DirectChatInfoMessage from './IntroductionMessages/DireactIntroMessages';
import IntroductionMessage from './IntroductionMessages/OpenItnroMessage';

/**
 * 
 * This component is used to render all the active chat channel messages
 * 
 * @param {object} props
 * @param {object} props.messages
 * @param {boolean} props.showTimestamp
 * @param {object} props.activeChannel
 * @param {number} props.currentUserId
 * @param {function} props.triggerActiveContent
 * @param {function} props.triggerEditMessage
 * @param {function} props.triggerDeleteMessage
 * 
 * @component
 * 
 * @example
 * 
 * <ChatMessages 
 *  activeChannelId={activeChannelId}
    messages={messages}
    showTimestamp={showTimestamp}
    activeChannel={activeChannel}
    currentUserId={currentUserId}
    triggerActiveContent={triggerActiveContent}
    triggerEditMessage={triggerEditMessage}
    triggerDeleteMessage={triggerDeleteMessage}
 * />
 */

function ChatMessages({
  activeChannelId,
  messages,
  showTimestamp,
  activeChannel,
  currentUserId,
  triggerActiveContent,
  triggerEditMessage,
  triggerDeleteMessage,
}) {
  if (!messages[activeChannelId]) {
    return null;
  }

  if (messages[activeChannelId].length === 0 && activeChannel) {
    switch (activeChannel.channel_type) {
      case 'direct':
        return <DirectChatInfoMessage activeChannel={activeChannel} />;
      case 'open':
        return <IntroductionMessage activeChannel={activeChannel} />;
      default:
        return null;
    }
  }

  return messages[activeChannelId].map((message) =>
    message.action ? (
      <ActionMessage
        user={message.username}
        profileImageUrl={message.profile_image_url}
        message={message.message}
        timestamp={showTimestamp ? message.timestamp : null}
        color={message.color}
        onContentTrigger={triggerActiveContent}
      />
    ) : (
      <Message
        currentUserId={currentUserId}
        id={message.id}
        user={message.username}
        userID={message.user_id}
        profileImageUrl={message.profile_image_url}
        message={message.message}
        timestamp={showTimestamp ? message.timestamp : null}
        editedAt={message.edited_at}
        color={message.color}
        onContentTrigger={triggerActiveContent}
        onDeleteMessageTrigger={triggerDeleteMessage}
        onEditMessageTrigger={triggerEditMessage}
      />
    ),
  );
}

Message.propTypes = {
  activeChannelId: PropTypes.number,
  messages: PropTypes.arrayOf(PropTypes.object),
  showTimestamp: PropTypes.bool,
  activeChannel: PropTypes.object,
  currentUserId: PropTypes.number,
  triggerActiveContent: PropTypes.func,
  triggerEditMessage: PropTypes.func,
  triggerDeleteMessage: PropTypes.func,
};

export default ChatMessages;
