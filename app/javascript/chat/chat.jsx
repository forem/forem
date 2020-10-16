import { h } from 'preact';
import { ConnectStateProvider } from './components/ConnectStateProvider';
import { connectReducer } from './connectReducer';
import ChatContent from './ChatContent';

const NARROW_WIDTH_LIMIT = 767;

function Chat(props) {
  const chatChannels = JSON.parse(props.chatChannels);
  const chatOptions = JSON.parse(props.chatOptions);

  const initialState = {
    appName: document.body.dataset.appName,
    messages: [],
    scrolled: false,
    showAlert: false,
    chatChannels,
    unopenedChannelIds: [],
    filterQuery: '',
    channelTypeFilter: 'all',
    channelsLoaded: false,
    channelPaginationNum: 0,
    fetchingPaginatedChannels: false,
    activeChannelId: chatOptions.activeChannelId,
    activeChannel: null,
    showChannelsList: chatOptions.showChannelsList,
    showTimestamp: chatOptions.showTimestamp,
    currentUserId: chatOptions.currentUserId,
    notificationsPermission: null,
    activeContent: {},
    fullscreenContent: null,
    videoPath: null,
    expanded: window.innerWidth > NARROW_WIDTH_LIMIT,
    isMobileDevice: typeof window.orientation !== 'undefined',
    subscribedPusherChannels: [],
    messageOffset: 0,
    showDeleteModal: false,
    messageDeleteId: null,
    allMessagesLoaded: false,
    currentMessageLocation: 0,
    startEditing: false,
    activeEditMessage: {},
    markdownEdited: false,
    searchShowing: false,
    channelUsers: [],
    showMemberlist: false,
    memberFilterQuery: null,
    rerenderIfUnchangedCheck: null,
    userRequestCount: 0,
    pusherKey: props.pusherKey,
    githubToken: props.githubToken,
  };

  return (
    <ConnectStateProvider initialState={initialState} reducer={connectReducer}>
      <ChatContent />
    </ConnectStateProvider>
  );
}

export default Chat;
