import { h } from 'preact';
import PropTypes from 'prop-types';
import { useContext } from 'preact/hooks';
import { processImageUpload } from '../../article-form/actions';
import { VideoContent } from '../videoContent';
import Compose from '../compose';
import Content from '../content';
import Alert from '../alert';
import { addSnackbarItem } from '../../Snackbar';
import { store } from '../components/ConnectStateProvider';
import {
  getAllMessages,
  conductModeration,
  sendMessage,
  editMessage,
  deleteMessage,
} from '../actions/actions';
import { scrollToBottom } from '../util';
import * as Type from '../components/ChatTypes';
import ChatMessages from './ChatMessages';
import DeleteModal from './Modal/DeleteModal';
import ActiveChannelMembershipList from './ActiveChannelMemberList';
import { DragAndDropZone } from '@utilities/dragAndDrop';

const WIDE_WIDTH_LIMIT = 1600;
const NARROW_WIDTH_LIMIT = 767;

const ActiveChatChannel = ({
  channelHeader,
  triggerActiveContent,
  setActiveContent,
  setActiveContentState,
  handleFailure,
}) => {
  const { state, dispatch } = useContext(store);

  const handleDragOver = (event) => {
    event.preventDefault();
    event.currentTarget.classList.add('opacity-25');
  };

  const handleDragExit = (event) => {
    event.preventDefault();
    event.currentTarget.classList.remove('opacity-25');
  };

  const handleImageDrop = (event) => {
    event.preventDefault();
    const { files } = event.dataTransfer;

    event.currentTarget.classList.remove('opacity-25');
    processImageUpload(files, handleImageSuccess, handleImageFailure);
  };

  const triggerEditMessage = (messageId) => {
    const { messages, activeChannelId } = state;
    const activeEditMessage = messages[activeChannelId].filter(
      (message) => message.id === messageId,
    )[0];

    updateState(Type.TRIGGER_EDIT_MESSAGE, {
      startEditing: true,
      activeEditMessage,
    });
  };

  const jumpBacktoBottom = () => {
    scrollToBottom();
    document
      .getElementById('jumpback_button')
      .classList.remove('chatchanneljumpback__hide');
  };

  const onTriggerVideoContent = (e) => {
    if (e.target.dataset.content === 'exit') {
      updateState(Type.EXIT_VIDEO_CONTENT, {
        videoPath: null,
        fullscreenContent: null,
        expanded: window.innerWidth > 600,
      });
    } else if (state.fullscreenContent === 'video') {
      updateState(Type.UPDATE_FULL_SCREEN_CONSTENT, {});
    } else {
      updateState(Type.HANDLE_SCREEN, {
        fullscreenContent: 'video',
        expanded: window.innerWidth > WIDE_WIDTH_LIMIT,
      });
    }
  };

  const handleKeyDownEdit = (e) => {
    const enterPressed = e.keyCode === 13;
    const targetValue = e.target.value;
    const messageIsEmpty = targetValue.length === 0;
    const shiftPressed = e.shiftKey;

    if (enterPressed) {
      if (messageIsEmpty) {
        e.preventDefault();
      } else if (!messageIsEmpty && !shiftPressed) {
        e.preventDefault();
        handleMessageSubmitEdit(e.target.value);
      }
    }
  };

  const handleKeyDown = (e) => {
    const {
      showMemberlist,
      activeContent,
      activeChannelId,
      messages,
      currentUserId,
    } = state;
    const enterPressed = e.keyCode === 13;
    const leftPressed = e.keyCode === 37;
    const rightPressed = e.keyCode === 39;
    const escPressed = e.keyCode === 27;
    const targetValue = e.target.value;
    const messageIsEmpty = targetValue.length === 0;
    const shiftPressed = e.shiftKey;
    const upArrowPressed = e.keyCode === 38;
    const deletePressed = e.keyCode === 46;

    if (enterPressed) {
      if (showMemberlist) {
        e.preventDefault();
        const selectedUser = document.querySelector('.active__message__list');
        addUserName({ target: selectedUser });
      } else if (messageIsEmpty) {
        e.preventDefault();
      } else if (!messageIsEmpty && !shiftPressed) {
        e.preventDefault();
        handleMessageSubmit(e.target.value);
      }
    }
    if (e.target.value.includes('@')) {
      if (e.keyCode === 40 || e.keyCode === 38) {
        e.preventDefault();
      }
    }
    if (
      leftPressed &&
      activeContent[activeChannelId] &&
      e.target.value === '' &&
      document.getElementById('activecontent-iframe')
    ) {
      e.preventDefault();
      try {
        e.target.value = document.getElementById(
          'activecontent-iframe',
        ).contentWindow.location.href;
      } catch (err) {
        e.target.value = activeContent[activeChannelId].path;
      }
    }
    if (
      rightPressed &&
      !activeContent[activeChannelId] &&
      e.target.value === ''
    ) {
      e.preventDefault();
      const richLinks = document.querySelectorAll('.chatchannels__richlink');
      if (richLinks.length === 0) {
        return;
      }
      setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      setActiveContent({
        path: richLinks[richLinks.length - 1].href,
        type_of: 'article',
      });
    }
    if (escPressed && activeContent[activeChannelId]) {
      setActiveContentState(activeChannelId, null);
      updateState(Type.HANDLE_SCREEN, {
        fullscreenContent: null,
        expanded: window.innerWidth > NARROW_WIDTH_LIMIT,
      });
    }
    if (messageIsEmpty) {
      const messagesByCurrentUser = messages[activeChannelId].filter(
        (message) => message.user_id === currentUserId,
      );
      const lastMessage =
        messagesByCurrentUser[messagesByCurrentUser.length - 1];

      if (lastMessage) {
        if (upArrowPressed) {
          triggerEditMessage(lastMessage.id);
        } else if (deletePressed) {
          triggerDeleteMessage(lastMessage.id);
        }
      }
    }
  };

  const handleImageSuccess = (res) => {
    const { links, image } = res;
    const mLink = `![${image[0].name}](${links[0]})`;
    const el = document.getElementById('messageform');
    const start = el.selectionStart;
    const end = el.selectionEnd;
    const text = el.value;
    let before = text.substring(0, start);
    before = text.substring(0, before.lastIndexOf('@') + 1);
    const after = text.substring(end, text.length);
    el.value = `${before + mLink} ${after}`;
    el.selectionStart = start + mLink.length + 1;
    el.selectionEnd = el.selectionStart;
    el.focus();
  };

  const handleImageFailure = (e) => {
    addSnackbarItem({ message: e.message, addCloseButton: true });
  };

  const handleMessageScroll = () => {
    const {
      allMessagesLoaded,
      messages,
      activeChannelId,
      messageOffset,
    } = state;

    if (!messages[activeChannelId]) {
      return;
    }

    const jumpbackButton = document.getElementById('jumpback_button');

    if (this.scroller) {
      const scrolledRatio =
        (this.scroller.scrollTop + this.scroller.clientHeight) /
        this.scroller.scrollHeight;

      if (scrolledRatio < 0.5) {
        jumpbackButton.classList.remove('chatchanneljumpback__hide');
      } else if (scrolledRatio > 0.6) {
        jumpbackButton.classList.add('chatchanneljumpback__hide');
      }

      if (this.scroller.scrollTop === 0 && !allMessagesLoaded) {
        getAllMessages(
          activeChannelId,
          messageOffset + messages[activeChannelId].length,
        ).then((res) => {
          addMoreMessages(res);
        });
        const curretPosition = this.scroller.scrollHeight;
        updateState(Type.CURRENT_MESSAGE_LOCATION, {
          currentMessageLocation: curretPosition,
        });
      }
    }
  };

  const addMoreMessages = (res) => {
    const { chatChannelId, messages } = res;

    if (messages.length > 0) {
      updateState(Type.ADD_MESSAGE, {
        chatChannelId,
        messages,
      });
    } else {
      updateState(Type.ALL_MESSAGE_LOADED, {
        allMessagesLoaded: true,
      });
    }
  };

  const triggerDeleteMessage = (messageId) => {
    updateState(Type.TRIGGER_DELETE_MESSAGE, {
      messageDeleteId: messageId,
      showDeleteModal: true,
    });
  };

  const handleCloseDeleteModal = () => {
    updateState(Type.CLOSE_DELETE_MODAL, {
      showDeleteModal: false,
      messageDeleteId: null,
    });
  };

  const addUserName = (e) => {
    const name =
      e.target.dataset.content || e.target.parentElement.dataset.content;
    const el = document.getElementById('messageform');
    const start = el.selectionStart;
    const end = el.selectionEnd;
    const text = el.value;
    let before = text.substring(0, start);
    before = text.substring(0, before.lastIndexOf('@') + 1);
    const after = text.substring(end, text.length);
    el.value = `${before + name} ${after}`;
    el.selectionStart = start + name.length + 1;
    el.selectionEnd = start + name.length + 1;
    el.focus();
    updateState(Type.SHOW_MEMBER_LIST, { showMemberlist: false });
  };

  const handleSubmitOnClick = (e) => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      handleMessageSubmit(message);
    }
  };

  const handleSubmitOnClickEdit = (e) => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      handleMessageSubmitEdit(message);
    }
  };

  const handleMessageSubmitEdit = (message) => {
    const { activeChannelId, activeEditMessage } = state;
    const editedMessage = {
      activeChannelId,
      id: activeEditMessage.id,
      message,
    };
    editMessage(editedMessage, handleSuccess, handleFailure);
    handleEditMessageClose();
  };

  const handleEditMessageClose = () => {
    updateState(Type.EDIT_MESSAGE_CLOSE, {
      startEditing: false,
      markdownEdited: false,
      activeEditMessage: { message: '', markdown: '' },
    });
  };

  const getMentionedUsers = (message) => {
    const { channelUsers, activeChannelId, activeChannel } = state;
    if (channelUsers[activeChannelId]) {
      if (message.includes('@all') && activeChannel.channel_type !== 'open') {
        return Array.from(
          Object.values(channelUsers[activeChannelId]).filter(
            (user) => user.id,
          ),
          (user) => user.id,
        );
      }
      return Array.from(
        Object.values(channelUsers[activeChannelId]).filter((user) =>
          message.includes(user.username),
        ),
        (user) => user.id,
      );
    }
    return null;
  };

  const handleMessageSubmit = (message) => {
    const { activeChannelId } = state;
    scrollToBottom();
    // should check if user has the privilege
    if (message.startsWith('/code')) {
      setActiveContentState(activeChannelId, { type_of: 'code_editor' });
    } else if (message.startsWith('/call')) {
      const messageObject = {
        activeChannelId,
        message: '/call',
        mentionedUsersId: getMentionedUsers(message),
      };
      updateState(Type.SET_VIDEO_PATH, {
        videoPath: `/video_chats/${activeChannelId}`,
      });
      sendMessage(messageObject, handleSuccess, handleFailure);
    } else if (message.startsWith('/play ')) {
      const messageObject = {
        activeChannelId,
        message,
        mentionedUsersId: getMentionedUsers(message),
      };
      sendMessage(messageObject, handleSuccess, handleFailure);
    } else if (message.startsWith('/new')) {
      setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      setActiveContent({
        path: '/new',
        type_of: 'article',
      });
    } else if (message.startsWith('/search')) {
      setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      setActiveContent({
        path: `/search?q=${message.replace('/search ', '')}`,
        type_of: 'article',
      });
    } else if (message.startsWith('/s ')) {
      setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      setActiveContent({
        path: `/search?q=${message.replace('/s ', '')}`,
        type_of: 'article',
      });
    } else if (message.startsWith('/ban ') || message.startsWith('/unban ')) {
      conductModeration(activeChannelId, message, handleSuccess, handleFailure);
    } else if (message.startsWith('/')) {
      setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      setActiveContent({
        path: message,
        type_of: 'article',
      });
    } else if (message.startsWith('/github')) {
      const args = message.split('/github ')[1].trim();
      setActiveContentState(activeChannelId, { type_of: 'github', args });
    } else {
      const messageObject = {
        activeChannelId,
        message,
        mentionedUsersId: getMentionedUsers(message),
      };
      updateState(Type.HANDLE_ALERT, {
        scrolled: false,
        showAlert: false,
      });
      sendMessage(messageObject, handleSuccess, handleFailure);
    }
  };

  const handleSuccess = (response) => {
    const { activeChannelId } = state;
    scrollToBottom();
    if (response.status === 'success') {
      if (response.message.temp_id) {
        const newMessages = state.messages;
        const foundIndex = state.messages[activeChannelId].findIndex(
          (message) => message.temp_id === response.message.temp_id,
        );
        if (foundIndex > 0) {
          newMessages[activeChannelId][foundIndex].id = response.message.id;
        }
        updateState(Type.UPDATE_MESSAGE_ON_SUCCESS, {
          messages: newMessages,
        });
      }
    } else if (response.status === 'moderation-success') {
      addSnackbarItem({ message: response.message, addCloseButton: true });
    } else if (response.status === 'error') {
      addSnackbarItem({ message: response.message, addCloseButton: true });
    }
  };

  const handleMention = (e) => {
    const { activeChannel } = state;
    const mention = e.keyCode === 64;
    if (mention && activeChannel.channel_type !== 'direct') {
      updateState(Type.SHOW_MEMBER_LIST, { showMemberlist: true });
    }
  };

  const handleKeyUp = (e) => {
    const { startEditing, activeChannel, showMemberlist } = state;
    const enterPressed = e.keyCode === 13;
    if (enterPressed && showMemberlist)
      updateState(Type.SHOW_MEMBER_LIST, { showMemberlist: false });
    if (activeChannel.channel_type !== 'direct') {
      if (startEditing) {
        updateState(Type.MARK_DOWN_EDITED, { markdownEdited: true });
      }
      if (!e.target.value.includes('@') && showMemberlist) {
        updateState(Type.SHOW_MEMBER_LIST, { showMemberlist: false });
      } else {
        setQuery(e.target);
        listHighlightManager(e.keyCode);
      }
    }
  };

  const setQuery = (e) => {
    const { showMemberlist } = state;
    if (showMemberlist) {
      const before = e.value.substring(0, e.selectionStart);
      const query = before.substring(
        before.lastIndexOf('@') + 1,
        e.selectionStart,
      );

      if (query.includes(' ') || before.lastIndexOf('@') < 0)
        updateState(Type.SHOW_MEMBER_LIST, { showMemberlist: false });
      else {
        updateState(Type.SHOW_MEMBER_LIST, { showMemberlist: true });
        updateState(Type.MEMBER_FILTER_QUERY, {
          memberFilterQuery: query,
        });
      }
    }
  };

  const listHighlightManager = (keyCode) => {
    const mentionList = document.getElementById('mentionList');
    const activeElement = document.querySelector('.active__message__list');
    if (mentionList.children.length > 0) {
      if (keyCode === 40 && activeElement) {
        if (activeElement.nextElementSibling) {
          activeElement.classList.remove('active__message__list');
          activeElement.nextElementSibling.classList.add(
            'active__message__list',
          );
        }
      } else if (keyCode === 38 && activeElement) {
        if (activeElement.previousElementSibling) {
          activeElement.classList.remove('active__message__list');
          activeElement.previousElementSibling.classList.add(
            'active__message__list',
          );
        }
      } else {
        mentionList.children[0].classList.add('active__message__list');
      }
    }
  };

  const handleMessageDelete = () => {
    const { messageDeleteId } = state;
    deleteMessage(messageDeleteId);
    updateState(Type.UPDATE_DELETE_MODAL_STATE, {
      showDeleteModal: false,
    });
  };

  const updateState = (type, data) => {
    dispatch({
      type,
      payload: data,
    });
  };

  return (
    <div className="activechatchannel">
      <div className="activechatchannel__conversation">
        {channelHeader}
        <DragAndDropZone
          onDragOver={handleDragOver}
          onDragExit={handleDragExit}
          onDrop={handleImageDrop}
        >
          <div
            className="activechatchannel__messages"
            onScroll={handleMessageScroll}
            ref={(scroller) => {
              this.scroller = scroller;
            }}
            id="messagelist"
          >
            <ChatMessages
              activeChannelId={state.activeChannelId}
              messages={state.messages}
              showTimestamp={state.showTimestamp}
              activeChannel={state.activeChannel}
              currentUserId={state.currentUserId}
              triggerActiveContent={triggerActiveContent}
              triggerEditMessage={triggerEditMessage}
              triggerDeleteMessage={triggerDeleteMessage}
            />
            <div className="messagelist__sentinel" id="messagelist__sentinel" />
          </div>
        </DragAndDropZone>
        <div
          className="chatchanneljumpback chatchanneljumpback__hide"
          id="jumpback_button"
        >
          <div
            role="button"
            className="chatchanneljumpback__messages"
            onClick={jumpBacktoBottom}
            tabIndex="0"
            onKeyUp={(e) => {
              if (e.keyCode === 13) jumpBacktoBottom();
            }}
          >
            Scroll to Bottom
          </div>
        </div>
        <DeleteModal
          showDeleteModal={state.showDeleteModal}
          handleMessageDelete={handleMessageDelete}
          handleCloseDeleteModal={handleCloseDeleteModal}
        />
        <div className="activechatchannel__alerts">
          <Alert showAlert={state.showAlert} />
        </div>
        <ActiveChannelMembershipList
          showMemberlist={state.showMemberlist}
          activeChannelId={state.activeChannelId}
          channelUsers={state.channelUsers}
          memberFilterQuery={state.memberFilterQuery}
          addUserName={addUserName}
        />
        <div className="activechatchannel__form">
          <Compose
            handleSubmitOnClick={handleSubmitOnClick}
            handleKeyDown={handleKeyDown}
            handleSubmitOnClickEdit={handleSubmitOnClickEdit}
            handleMention={handleMention}
            handleKeyUp={handleKeyUp}
            handleKeyDownEdit={handleKeyDownEdit}
            activeChannelId={state.activeChannelId}
            startEditing={state.startEditing}
            markdownEdited={state.markdownEdited}
            editMessageMarkdown={state.activeEditMessage.markdown}
            handleEditMessageClose={handleEditMessageClose}
          />
        </div>
      </div>
      <Content
        onTriggerContent={triggerActiveContent}
        resource={state.activeContent[state.activeChannelId]}
        activeChannel={state.activeChannel}
        fullscreen={state.fullscreenContent === 'sidecar'}
      />
      <VideoContent
        videoPath={state.videoPath}
        onTriggerVideoContent={onTriggerVideoContent}
        fullscreen={state.fullscreenContent === 'video'}
      />
    </div>
  );
};

ActiveChatChannel.propTypes = {
  channelHeader: PropTypes.element.isRequired,
  setActiveContentState: PropTypes.func.isRequired,
  setActiveContent: PropTypes.func.isRequired,
  handleFailure: PropTypes.func.isRequired,
  triggerActiveContent: PropTypes.func.isRequired,
};

export default ActiveChatChannel;
