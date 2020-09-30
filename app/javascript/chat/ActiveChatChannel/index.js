import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { processImageUpload } from '../../article-form/actions';
import Message from '../message';
import { VideoContent } from '../videoContent';
import Compose from '../compose';
import Content from '../content';
import Alert from '../alert';
import { addSnackbarItem } from '../../Snackbar';
import { scrollToBottom } from '../util';
import { deleteMessage, editMessage } from '../actions/actions';
import ChatMessages from './ChatMessages';
import DeleteModal from './Modal/DeleteModal';
import ActiveChannelMembershipList from './ActiveChannelMemberList';
import { DragAndDropZone } from '@utilities/dragAndDrop';

// const NARROW_WIDTH_LIMIT = 767;
// const _WIDE_WIDTH_LIMIT = 1600;

const ActiveChatChannel = ({
  activeChannelId,
  messages,
  showTimestamp,
  activeChannel,
  currentUserId,
  triggerActiveContent,
  channelUsers,
  memberFilterQuery,
  addUserName,
  state,
  channelHeader,
  activeContent,
  handleMessageSubmit,
  handleMessageScroll,
  // handleMessageSubmitEdit,
  // handleEditMessageClose,
  onTriggerVideoContent,
  setQuery,
  listHighlightManager,
  handleSuccess,
  handleFailure,
}) => {
  const [showMemberlist, setShowMemberlist] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [messageDeleteId, setMessageDeleteId] = useState(null);
  const [activeEditMessage, setActiveEditMessage] = useState({});
  const [startEditing, setStartEditing] = useState(false);
  const [markdownEdited, setMarkdownEdited] = useState(false);

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

  const handleImageFailure = (e) => {
    addSnackbarItem({ message: e.message, addCloseButton: true });
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

  const jumpBacktoBottom = () => {
    scrollToBottom();
    document
      .getElementById('jumpback_button')
      .classList.remove('chatchanneljumpback__hide');
  };

  const handleCloseDeleteModal = () => {
    setShowDeleteModal(false);
    setMessageDeleteId(null);
  };

  const handleMessageDelete = () => {
    deleteMessage(messageDeleteId);
    setShowDeleteModal(false);
  };

  const triggerDeleteMessage = (messageId) => {
    setMessageDeleteId(messageId);
    setShowDeleteModal(true);
  };

  const handleKeyDown = (e) => {
    const enterPressed = e.keyCode === 13;
    const leftPressed = e.keyCode === 37;
    const rightPressed = e.keyCode === 39;
    // const escPressed = e.keyCode === 27;
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
        e.target.value = '';
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
      // this.setActiveContentState(activeChannelId, {
      //   type_of: 'loading-post',
      // });
      // this.setActiveContent({
      //   path: richLinks[richLinks.length - 1].href,
      //   type_of: 'article',
      // });
    }
    // if (escPressed && activeContent[activeChannelId]) {
    //   this.setActiveContentState(activeChannelId, null);
    //   this.setState({
    //     fullscreenContent: null,
    //     expanded: window.innerWidth > NARROW_WIDTH_LIMIT,
    //   });
    // }
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

  const handleKeyDownEdit = (e) => {
    console.log(e);
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
        e.target.value = '';
      }
    }
  };

  const handleKeyUp = (e) => {
    // const {activeChannel, showMemberlist } = state;
    const enterPressed = e.keyCode === 13;
    if (enterPressed && showMemberlist) setShowMemberlist(false);

    if (activeChannel.channel_type !== 'direct') {
      if (startEditing) {
        setShowMemberlist(true);
      }
      if (!e.target.value.includes('@') && showMemberlist) {
        setShowMemberlist(false);
      } else {
        setQuery(e.target);
        listHighlightManager(e.keyCode);
      }
    }
  };

  const handleMention = (e) => {
    const { activeChannel } = state;
    const mention = e.keyCode === 64;
    if (mention && activeChannel.channel_type !== 'direct') {
      setShowMemberlist(true);
    }
  };

  const handleSubmitOnClick = (e) => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      handleMessageSubmit(message);
      document.getElementById('messageform').value = '';
    }
  };

  const handleSubmitOnClickEdit = (e) => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      handleMessageSubmitEdit(message);
      document.getElementById('messageform').value = '';
    }
  };

  const handleMessageSubmitEdit = (message) => {
    // const { activeChannelId, activeEditMessage } = state;
    const editedMessage = {
      activeChannelId,
      id: activeEditMessage.id,
      message,
    };
    editMessage(editedMessage, handleSuccess, handleFailure);
    handleEditMessageClose();
  };

  const triggerEditMessage = (messageId) => {
    // const { activeChannelId } = state;
    // this.setState({
    //   activeEditMessage: messages[activeChannelId].filter(
    //     (message) => message.id === messageId,
    //   )[0],
    // });
    // console.log(messages[activeChannelId].filter(
    //   (message) => message.id === messageId,
    // )[0])
    setActiveEditMessage(
      messages[activeChannelId].filter(
        (message) => message.id === messageId,
      )[0],
    );
    setStartEditing(true);
    // this.setState({ startEditing: true });
  };

  const handleEditMessageClose = () => {
    const textarea = document.getElementById('messageform');
    setStartEditing(false);
    setActiveEditMessage({ message: '', markdown: '' });
    setMarkdownEdited(false);
    // this.setState({
    // startEditing: false,
    // markdownEdited: false,
    // activeEditMessage: { message: '', markdown: '' },
    // });
    textarea.value = '';
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
              activeChannelId={activeChannelId}
              messages={messages}
              showTimestamp={showTimestamp}
              activeChannel={activeChannel}
              currentUserId={currentUserId}
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
          showDeleteModal={showDeleteModal}
          handleMessageDelete={handleMessageDelete}
          handleCloseDeleteModal={handleCloseDeleteModal}
        />
        <div className="activechatchannel__alerts">
          <Alert showAlert={state.showAlert} />
        </div>
        <ActiveChannelMembershipList
          showMemberlist={showMemberlist}
          activeChannelId={activeChannelId}
          channelUsers={channelUsers}
          memberFilterQuery={memberFilterQuery}
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
            activeChannelId={activeChannelId}
            startEditing={startEditing}
            markdownEdited={markdownEdited}
            editMessageMarkdown={activeEditMessage.markdown}
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

Message.propTypes = {
  activeChannelId: PropTypes.number,
  messages: PropTypes.arrayOf(PropTypes.object),
  showTimestamp: PropTypes.bool,
  activeChannel: PropTypes.object,
  currentUserId: PropTypes.number,
  triggerActiveContent: PropTypes.func,
  // triggerEditMessage: PropTypes.func,
  showMemberlist: PropTypes.bool,
  channelUsers: PropTypes.array,
  memberFilterQuery: PropTypes.string,
  addUserName: PropTypes.func,
  state: PropTypes.object,
  channelHeader: PropTypes.element,
  activeContent: PropTypes.object,
  handleMessageSubmit: PropTypes.func,
  handleMessageScroll: PropTypes.func,
  // handleMessageSubmitEdit: PropTypes.func,
  // handleEditMessageClose: PropTypes.func,
  onTriggerVideoContent: PropTypes.func,
  setQuery: PropTypes.func,
  listHighlightManager: PropTypes.func,
  handleSuccess: PropTypes.func,
  handleFailure: PropTypes.func,
};

export default ActiveChatChannel;
