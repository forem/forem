import { h } from 'preact';
import PropTypes from 'prop-types';
import { useContext } from 'preact/hooks';
import { processImageUpload } from '../../article-form/actions';
import Message from '../message';
import { VideoContent } from '../videoContent';
import Compose from '../compose';
import Content from '../content';
import Alert from '../alert';
import { addSnackbarItem } from '../../Snackbar';
import { store } from '../components/ConnectStateProvider';
import ChatMessages from './ChatMessages';
import DeleteModal from './Modal/DeleteModal';
import ActiveChannelMembershipList from './ActiveChannelMemberList';
import { DragAndDropZone } from '@utilities/dragAndDrop';

const ActiveChatChannel = ({
  channelHeader,
  addUserName,
  handleMessageScroll,
  triggerActiveContent,
  triggerEditMessage,
  triggerDeleteMessage,
  jumpBacktoBottom,
  onTriggerVideoContent,
  handleEditMessageClose,
  handleSubmitOnClick,
  handleKeyDown,
  handleSubmitOnClickEdit,
  handleMention,
  handleKeyUp,
  handleKeyDownEdit,
  // handleCloseDeleteModal,
  handleMessageDelete,
}) => {
  const { state } = useContext(store);
  console.log(state);

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

  const handleCloseDeleteModal = () => {
    // dispatch({
    //   type: 'closeDeleteModal',
    //   payload: {
    //     showDeleteModal: false
    //   }
    // });
    // this.setState({ showDeleteModal: false, messageDeleteId: null });
  };
  // dispatch({
  //   type: "add_message",
  // })
  // this.setState({ showDeleteModal: false, messageDeleteId: null });
  // }

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

Message.propTypes = {
  channelHeader: PropTypes.element,
  addUserName: PropTypes.func,
  handleMessageScroll: PropTypes.func,
  triggerDeleteMessage: PropTypes.func,
  jumpBacktoBottom: PropTypes.func,
  onTriggerVideoContent: PropTypes.func,
  handleSubmitOnClick: PropTypes.func,
  handleKeyDown: PropTypes.func,
  handleSubmitOnClickEdit: PropTypes.func,
  handleMention: PropTypes.func,
  handleKeyUp: PropTypes.func,
  handleKeyDownEdit: PropTypes.func,
  handleEditMessageClose: PropTypes.func,
  triggerEditMessage: PropTypes.func,
  handleMessageDelete: PropTypes.func,
  // handleCloseDeleteModal: PropTypes.func,
};

export default ActiveChatChannel;
