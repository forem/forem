import { h } from 'preact';
import PropTypes from 'prop-types';
import ActionMessage from '../actionMessage';
import Message from '../message';
import DirectChatInfoMessage from './IntroductionMessages/DireactIntroMessages';
import OpenChatInfoMessagge from './IntroductionMessages/OpenItnroMessage';

const ChatMessages = ({
  activeChannelId,
  messages,
  showTimestamp,
  activeChannel,
  currentUserId,
  triggerActiveContent,
  triggerEditMessage,
  triggerDeleteMessage,
}) => {
  if (!messages[activeChannelId]) {
    return null;
  }

  if (messages[activeChannelId].length === 0 && activeChannel) {
    switch (activeChannel.channel_type) {
      case 'direct':
        return <DirectChatInfoMessage activeChannel={activeChannel} />;
      case 'open':
        return <OpenChatInfoMessagge activeChannel={activeChannel} />;
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
};

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
