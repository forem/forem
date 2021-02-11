import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { setupPusher } from '../utilities/connect';
import { notifyUser } from '../utilities/connect/newMessageNotify';
import { debounceAction } from '../utilities/debounceAction';
import { addSnackbarItem } from '../Snackbar';
import { processImageUpload } from '../article-form/actions';
import {
  conductModeration,
  getAllMessages,
  sendMessage,
  sendOpen,
  getChannels,
  getUnopenedChannelIds,
  getContent,
  deleteMessage,
  editMessage,
} from './actions/actions';
import { CreateChatModal } from './components/CreateChatModal';
import { ChannelFilterButton } from './components/ChannelFilterButton';
import {
  sendChannelRequest,
  rejectJoiningRequest,
  acceptJoiningRequest,
  getChannelRequestInfo,
} from './actions/requestActions';
import {
  hideMessages,
  scrollToBottom,
  setupObserver,
  getCurrentUser,
} from './util';
import { Alert } from './alert';
import { Channels } from './channels';
import { Compose } from './compose';
import { Message } from './message';
import { ActionMessage } from './actionMessage';
import { Content } from './content';
import { VideoContent } from './videoContent';
import { DragAndDropZone } from '@utilities/dragAndDrop';
import { dragAndUpload } from '@utilities/dragAndUpload';
import { Button } from '@crayons';

const NARROW_WIDTH_LIMIT = 767;
const WIDE_WIDTH_LIMIT = 1600;

export class Chat extends Component {
  static propTypes = {
    pusherKey: PropTypes.number.isRequired,
    chatChannels: PropTypes.string.isRequired,
    chatOptions: PropTypes.string.isRequired,
    githubToken: PropTypes.string.isRequired,
    tagModerator: PropTypes.shape({ isTagModerator: PropTypes.bool.isRequired })
      .isRequired,
  };

  constructor(props) {
    super(props);
    const chatChannels = JSON.parse(props.chatChannels);
    const chatOptions = JSON.parse(props.chatOptions);

    this.debouncedChannelFilter = debounceAction(
      this.triggerChannelFilter.bind(this),
    );

    this.state = {
      appDomain: document.body.dataset.appDomain,
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
      openModal: false,
      isTagModerator: JSON.parse(props.tagModerator).isTagModerator,
    };
    if (chatOptions.activeChannelId) {
      getAllMessages(chatOptions.activeChannelId, 0, this.receiveAllMessages);
    }
  }

  componentDidMount() {
    const {
      chatChannels,
      activeChannelId,
      showChannelsList,
      channelTypeFilter,
      isMobileDevice,
      channelPaginationNum,
      currentUserId,
      appDomain,
    } = this.state;

    this.setupChannels(chatChannels);

    const channelsForPusherSub = chatChannels.filter(
      this.channelTypeFilterFn('open'),
    );
    this.subscribeChannelsToPusher(
      channelsForPusherSub,
      (channel) => `open-channel--${appDomain}-${channel.chat_channel_id}`,
    );

    setupObserver(this.observerCallback);

    this.subscribePusher(
      `private-message-notifications--${appDomain}-${currentUserId}`,
    );

    if (activeChannelId) {
      sendOpen(activeChannelId, this.handleChannelOpenSuccess, null);
    }
    if (showChannelsList) {
      const filters =
        channelTypeFilter === 'all'
          ? {}
          : { filters: `channel_type:${channelTypeFilter}` };
      const searchParams = {
        query: '',
        retrievalID: activeChannelId,
        searchType: '',
        paginationNumber: channelPaginationNum,
      };
      if (activeChannelId !== null) {
        searchParams.searchType = 'discoverable';
      }
      getChannels(searchParams, filters, this.loadChannels);
      getUnopenedChannelIds(this.markUnopenedChannelIds);
    }
    if (!isMobileDevice) {
      document.getElementById('messageform').focus();
    }
    if (document.getElementById('chatchannels__channelslist')) {
      document
        .getElementById('chatchannels__channelslist')
        .addEventListener('scroll', this.handleChannelScroll);
    }

    this.handleRequestCount();
  }

  shouldComponentUpdate(nextProps, nextState) {
    if (
      this.state.rerenderIfUnchangedCheck !== nextState.rerenderIfUnchangedCheck
    ) {
      return false;
    }
  }

  componentDidUpdate() {
    const { scrolled, currentMessageLocation } = this.state;
    const messageList = document.getElementById('messagelist');
    if (messageList) {
      if (!scrolled) {
        scrollToBottom();
      }
    }

    if (currentMessageLocation && messageList.scrollTop === 0) {
      messageList.scrollTop =
        messageList.scrollHeight - (currentMessageLocation + 30);
    }
  }

  handleRequestCount = () => {
    getChannelRequestInfo().then((response) => {
      const { result } = response;
      const { user_joining_requests, channel_joining_memberships } = result;
      let totalRequest =
        user_joining_requests?.length + channel_joining_memberships?.length;
      this.setState({
        userRequestCount: totalRequest,
      });
    });
  };

  filterForActiveChannel = (channels, id, currentUserId) =>
    channels.filter(
      (channel) =>
        channel.chat_channel_id === parseInt(id, 10) &&
        channel.viewable_by === parseInt(currentUserId, 10),
    )[0];

  subscribePusher = (channelName) => {
    const { subscribedPusherChannels } = this.state;
    const { pusherKey } = this.props;
    if (!subscribedPusherChannels.includes(channelName)) {
      setupPusher(pusherKey, {
        channelId: channelName,
        messageCreated: this.receiveNewMessage,
        messageDeleted: this.removeMessage,
        messageEdited: this.updateMessage,
        channelCleared: this.clearChannel,
        redactUserMessages: this.redactUserMessages,
        channelError: this.channelError,
        mentioned: this.mentioned,
        messageOpened: this.messageOpened,
      });
      const subscriptions = subscribedPusherChannels;
      subscriptions.push(channelName);
      this.setState({ subscribedPusherChannels: subscriptions });
    }
  };

  mentioned = () => {};

  messageOpened = () => {};

  loadChannels = (channels, query) => {
    const { activeChannelId, appDomain } = this.state;
    const activeChannel =
      this.state.activeChannel ||
      channels.filter(
        (channel) => channel.chat_channel_id === activeChannelId,
      )[0];
    if (activeChannelId && query.length === 0) {
      this.setState({
        chatChannels: channels,
        scrolled: false,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: '',
        activeChannel:
          activeChannel ||
          this.filterForActiveChannel(channels, activeChannelId),
      });
      this.setupChannel(activeChannelId, activeChannel);
    } else if (activeChannelId) {
      this.setState({
        scrolled: false,
        chatChannels: channels,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query,
        activeChannel:
          activeChannel ||
          this.filterForActiveChannel(channels, activeChannelId),
      });
      this.setupChannel(activeChannelId, activeChannel);
    } else if (channels.length > 0) {
      this.setState({
        chatChannels: channels,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query || '',
        scrolled: false,
      });

      this.triggerSwitchChannel(
        channels[0].chat_channel_id,
        channels[0].channel_modified_slug,
        channels,
      );
      this.setupChannels(channels);
    } else {
      this.setState({ channelsLoaded: true });
    }
    this.subscribeChannelsToPusher(
      channels.filter(this.channelTypeFilterFn('open')),
      (channel) => `open-channel--${appDomain}-${channel.chat_channel_id}`,
    );
    this.subscribeChannelsToPusher(
      channels.filter(this.channelTypeFilterFn('invite_only')),
      (channel) => `private-channel--${appDomain}-${channel.chat_channel_id}`,
    );
    const chatChannelsList = document.getElementById(
      'chatchannels__channelslist',
    );

    if (chatChannelsList) {
      chatChannelsList.scrollTop = 0;
    }
  };

  markUnopenedChannelIds = (ids) => {
    this.setState({ unopenedChannelIds: ids });
  };

  subscribeChannelsToPusher = (channels, channelNameFn) => {
    channels.forEach((channel) => {
      this.subscribePusher(channelNameFn(channel));
    });
  };

  channelTypeFilterFn = (type) => (channel) => {
    return channel.channel_type === type;
  };

  setupChannels = (channels) => {
    const { activeChannel } = this.state;
    channels.forEach((channel, index) => {
      if (index < 3) {
        this.setupChannel(channel.chat_channel_id, activeChannel);
      }
    });
  };

  loadPaginatedChannels = (channels) => {
    const { state } = this;
    const currentChannels = state.chatChannels;
    const currentChannelIds = currentChannels.map((channel) => channel.id);
    const newChannels = currentChannels;
    channels.forEach((channel) => {
      if (!currentChannelIds.includes(channel.id)) {
        newChannels.push(channel);
      }
    });
    if (
      currentChannels.length === newChannels.length &&
      state.channelPaginationNum > 3
    ) {
      return;
    }
    this.setState({
      chatChannels: newChannels,
      fetchingPaginatedChannels: false,
      channelPaginationNum: state.channelPaginationNum + 1,
    });
  };

  setupChannel = (channelId, activeChannel) => {
    const { messages, messageOffset, appDomain } = this.state;
    if (
      !messages[channelId] ||
      messages[channelId].length === 0 ||
      messages[channelId][0].reception_method === 'pushed'
    ) {
      getAllMessages(channelId, messageOffset, this.receiveAllMessages);
    }
    if (
      activeChannel &&
      activeChannel.channel_type !== 'direct' &&
      activeChannel.chat_channel_id === channelId
    ) {
      getContent(
        `/chat_channels/${channelId}/channel_info`,
        this.setOpenChannelUsers,
        null,
      );
      if (activeChannel.channel_type === 'open')
        this.subscribePusher(`open-channel--${appDomain}-${channelId}`);
    }
    this.subscribePusher(`private-channel--${appDomain}-${channelId}`);
  };

  setOpenChannelUsers = (res) => {
    const { activeChannelId, activeChannel } = this.state;
    Object.filter = (obj, predicate) =>
      Object.fromEntries(Object.entries(obj).filter(predicate));
    const leftUser = Object.filter(
      res.channel_users,
      ([username]) => username !== window.currentUser.username,
    );
    if (activeChannel && activeChannel.channel_type === 'open') {
      this.setState({
        channelUsers: {
          [activeChannelId]: leftUser,
        },
      });
    } else {
      this.setState({
        channelUsers: {
          [activeChannelId]: {
            all: { username: 'all', name: 'To notify everyone here' },
            ...leftUser,
          },
        },
      });
    }
  };

  observerCallback = (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting && this.state.scrolled === true) {
        this.setState({ scrolled: false, showAlert: false });
      } else if (this.state.scrolled === false) {
        this.setState({
          scrolled: true,
          rerenderIfUnchangedCheck: Math.random(),
        });
      }
    });
  };

  channelError = (_error) => {
    this.setState({
      subscribedPusherChannels: [],
    });
  };

  receiveAllMessages = (res) => {
    const { chatChannelId, messages } = res;
    this.setState((prevState) => ({
      messages: { ...prevState.messages, [chatChannelId]: messages },
      scrolled: false,
    }));
  };

  removeMessage = (message) => {
    const { activeChannelId } = this.state;
    this.setState((prevState) => ({
      messages: {
        [activeChannelId]: [
          ...prevState.messages[activeChannelId].filter(
            (oldmessage) => oldmessage.id !== message.id,
          ),
        ],
      },
    }));
  };

  updateMessage = (message) => {
    const { activeChannelId } = this.state;
    if (message.chat_channel_id === activeChannelId) {
      this.setState(({ messages }) => {
        const newMessages = messages;
        const foundIndex = messages[activeChannelId].findIndex(
          (oldMessage) => oldMessage.id === message.id,
        );
        newMessages[activeChannelId][foundIndex] = message;
        return { messages: newMessages };
      });
    }
  };

  receiveNewMessage = (message) => {
    const {
      messages,
      activeChannelId,
      chatChannels,
      currentUserId,
      unopenedChannelIds,
    } = this.state;

    const receivedChatChannelId = message.chat_channel_id;
    const messageList = document.getElementById('messagelist');
    let newMessages = [];
    const nearBottom =
      messageList.scrollTop + messageList.offsetHeight + 400 >
      messageList.scrollHeight;

    if (nearBottom) {
      scrollToBottom();
    }

    // If I'm not sender and tab is not active
    if (message.user_id !== currentUserId && document.hidden) {
      notifyUser();
    }

    if (
      message.temp_id &&
      messages[receivedChatChannelId] &&
      messages[receivedChatChannelId].findIndex(
        (oldmessage) => oldmessage.temp_id === message.temp_id,
      ) > -1
    ) {
      // Remove reduntant messages
      return;
    }

    if (messages[receivedChatChannelId]) {
      newMessages = messages[receivedChatChannelId].slice();
      newMessages.push(message);
      if (newMessages.length > 150) {
        newMessages.shift();
      }
    }

    // Show alert if message received and you have scrolled up
    const newShowAlert =
      activeChannelId === receivedChatChannelId
        ? { showAlert: !nearBottom }
        : {};

    let newMessageChannelIndex = 0;
    let newMessageChannel = null;
    const newChannelsObj = chatChannels.map((channel, index) => {
      if (receivedChatChannelId === channel.chat_channel_id) {
        newMessageChannelIndex = index;
        newMessageChannel = channel;
        return { ...channel, channel_last_message_at: new Date() };
      }
      return channel;
    });

    if (newMessageChannelIndex > 0) {
      newChannelsObj.splice(newMessageChannelIndex, 1);
      newChannelsObj.unshift(newMessageChannel);
    }

    // Mark messages read
    if (receivedChatChannelId === activeChannelId) {
      sendOpen(receivedChatChannelId, this.handleChannelOpenSuccess, null);
    } else {
      const newUnopenedChannels = unopenedChannelIds;
      if (!unopenedChannelIds.includes(receivedChatChannelId)) {
        newUnopenedChannels.push(receivedChatChannelId);
      }
      this.setState({
        unopenedChannelIds: newUnopenedChannels,
      });
    }

    // Updating the messages
    this.setState((prevState) => ({
      ...newShowAlert,
      chatChannels: newChannelsObj,
      messages: {
        ...prevState.messages,
        [receivedChatChannelId]: newMessages,
      },
    }));
  };

  redactUserMessages = (res) => {
    const { messages } = this.state;
    const newMessages = hideMessages(messages, res.userId);
    this.setState({ messages: newMessages });
  };

  clearChannel = (res) => {
    this.setState((prevState) => ({
      messages: { ...prevState.messages, [res.chat_channel_id]: [] },
    }));
  };

  handleChannelScroll = (e) => {
    const {
      fetchingPaginatedChannels,
      chatChannels,
      channelTypeFilter,
      filterQuery,
      activeChannelId,
      channelPaginationNum,
    } = this.state;

    if (fetchingPaginatedChannels || chatChannels.length < 30) {
      return;
    }
    const { target } = e;
    if (target.scrollTop + target.offsetHeight + 1800 > target.scrollHeight) {
      this.setState({ fetchingPaginatedChannels: true });

      const filters =
        channelTypeFilter === 'all'
          ? {}
          : { filters: `channel_type:${channelTypeFilter}` };
      const searchParams = {
        query: filterQuery,
        retrievalID: activeChannelId,
        searchType: '',
        paginationNumber: channelPaginationNum,
      };
      getChannels(searchParams, filters, this.loadPaginatedChannels);
    }
  };

  handleKeyDown = (e) => {
    const {
      showMemberlist,
      activeContent,
      activeChannelId,
      messages,
      currentUserId,
    } = this.state;
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
        const selectedUser = document.getElementsByClassName(
          'active__message__list',
        )[0];
        this.addUserName({ target: selectedUser });
      } else if (messageIsEmpty) {
        e.preventDefault();
      } else if (!messageIsEmpty && !shiftPressed) {
        e.preventDefault();
        this.handleMessageSubmit(e.target.value);
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
      const richLinks = document.getElementsByClassName(
        'chatchannels__richlink',
      );
      if (richLinks.length === 0) {
        return;
      }
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: richLinks[richLinks.length - 1].href,
        type_of: 'article',
      });
    }
    if (escPressed && activeContent[activeChannelId]) {
      this.setActiveContentState(activeChannelId, null);
      this.setState({
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
          this.triggerEditMessage(lastMessage.id);
        } else if (deletePressed) {
          this.triggerDeleteMessage(lastMessage.id);
        }
      }
    }
  };

  handleKeyDownEdit = (e) => {
    const enterPressed = e.keyCode === 13;
    const targetValue = e.target.value;
    const messageIsEmpty = targetValue.length === 0;
    const shiftPressed = e.shiftKey;

    if (enterPressed) {
      if (messageIsEmpty) {
        e.preventDefault();
      } else if (!messageIsEmpty && !shiftPressed) {
        e.preventDefault();
        this.handleMessageSubmitEdit(e.target.value);
      }
    }
  };

  handleMessageSubmitEdit = (message) => {
    const { activeChannelId, activeEditMessage } = this.state;
    const editedMessage = {
      activeChannelId,
      id: activeEditMessage.id,
      message,
    };
    editMessage(editedMessage, this.handleSuccess, this.handleFailure);
    this.handleEditMessageClose();
  };

  handleMessageSubmit = (message) => {
    const { activeChannelId } = this.state;
    scrollToBottom();
    // should check if user has the privilege
    if (message.startsWith('/code')) {
      this.setActiveContentState(activeChannelId, { type_of: 'code_editor' });
    } else if (message.startsWith('/call')) {
      const messageObject = {
        activeChannelId,
        message: '/call',
        mentionedUsersId: this.getMentionedUsers(message),
      };
      this.setState({ videoPath: `/video_chats/${activeChannelId}` });
      sendMessage(messageObject, this.handleSuccess, this.handleFailure);
    } else if (message.startsWith('/play ')) {
      const messageObject = {
        activeChannelId,
        message,
        mentionedUsersId: this.getMentionedUsers(message),
      };
      sendMessage(messageObject, this.handleSuccess, this.handleFailure);
    } else if (message.startsWith('/new')) {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: '/new',
        type_of: 'article',
      });
    } else if (message.startsWith('/search')) {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: `/search?q=${message.replace('/search ', '')}`,
        type_of: 'article',
      });
    } else if (message.startsWith('/s ')) {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: `/search?q=${message.replace('/s ', '')}`,
        type_of: 'article',
      });
    } else if (message.startsWith('/ban ') || message.startsWith('/unban ')) {
      conductModeration(
        activeChannelId,
        message,
        this.handleSuccess,
        this.handleFailure,
      );
    } else if (message.startsWith('/draw')) {
      this.setActiveContent({
        sendCanvasImage: this.sendCanvasImage,
        type_of: 'draw',
      });
    } else if (message.startsWith('/')) {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: message,
        type_of: 'article',
      });
    } else if (message.startsWith('/github')) {
      const args = message.split('/github ')[1].trim();
      this.setActiveContentState(activeChannelId, { type_of: 'github', args });
    } else {
      const messageObject = {
        activeChannelId,
        message,
        mentionedUsersId: this.getMentionedUsers(message),
      };
      this.setState({ scrolled: false, showAlert: false });
      sendMessage(messageObject, this.handleSuccess, this.handleFailure);
    }
  };
  hideChannelList = () => {
    const chatContainer = document.getElementsByClassName(
      'chat__activechat',
    )[0];
    chatContainer.classList.remove('chat__activechat--hidden');
  };
  handleSwitchChannel = (e) => {
    e.preventDefault();
    let { target } = e;
    this.hideChannelList();
    if (!target.dataset.channelId) {
      target = target.parentElement;
    }
    this.triggerSwitchChannel(
      parseInt(target.dataset.channelId, 10),
      target.dataset.channelSlug,
    );
  };

  triggerSwitchChannel = (id, slug, channels) => {
    const {
      chatChannels,
      isMobileDevice,
      unopenedChannelIds,
      activeChannelId,
      currentUserId,
    } = this.state;
    const channelList = channels || chatChannels;
    const newUnopenedChannelIds = unopenedChannelIds;
    const index = newUnopenedChannelIds.indexOf(id);
    if (index > -1) {
      newUnopenedChannelIds.splice(index, 1);
    }

    let updatedActiveChannel = this.filterForActiveChannel(
      channelList,
      id,
      currentUserId,
    );

    this.setState({
      activeChannel: updatedActiveChannel,
      activeChannelId: parseInt(id, 10),
      scrolled: false,
      showAlert: false,
      allMessagesLoaded: false,
      showMemberlist: false,
      unopenedChannelIds: unopenedChannelIds.filter(
        (unopenedId) => unopenedId !== id,
      ),
    });

    this.setupChannel(id, updatedActiveChannel);
    const params = new URLSearchParams(window.location.search);

    if (params.get('ref') === 'group_invite') {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: '/chat_channel_memberships',
        type_of: 'article',
      });
    }
    window.history.replaceState(null, null, `/connect/${slug}`);
    if (!isMobileDevice) {
      document.getElementById('messageform').focus();
    }
    if (window.ga && ga.create) {
      ga('send', 'pageview', window.location.pathname + window.location.search);
    }
    sendOpen(id, this.handleChannelOpenSuccess, null);
  };

  handleSubmitOnClick = (e) => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      this.handleMessageSubmit(message);
    }
  };

  handleSubmitOnClickEdit = (e) => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      this.handleMessageSubmitEdit(message);
    }
  };

  triggerDeleteMessage = (messageId) => {
    this.setState({ messageDeleteId: messageId });
    this.setState({ showDeleteModal: true });
  };

  triggerEditMessage = (messageId) => {
    const { messages, activeChannelId } = this.state;
    this.setState({
      activeEditMessage: messages[activeChannelId].filter(
        (message) => message.id === messageId,
      )[0],
    });
    this.setState({ startEditing: true });
  };

  handleSuccess = (response) => {
    const { activeChannelId } = this.state;
    scrollToBottom();
    if (response.status === 'success') {
      if (response.message.temp_id) {
        this.setState(({ messages }) => {
          const newMessages = messages;
          const foundIndex = messages[activeChannelId].findIndex(
            (message) => message.temp_id === response.message.temp_id,
          );
          if (foundIndex > 0) {
            newMessages[activeChannelId][foundIndex].id = response.message.id;
          }
          return { messages: newMessages };
        });
      }
    } else if (response.status === 'moderation-success') {
      addSnackbarItem({ message: response.message, addCloseButton: true });
    } else if (response.status === 'error') {
      addSnackbarItem({ message: response.message, addCloseButton: true });
    }
  };

  handleRequestRejection = (e) => {
    rejectJoiningRequest(
      e.target.dataset.channelId,
      e.target.dataset.membershipId,
      this.handleJoiningManagerSuccess(e.target.dataset.membershipId),
      null,
    );
  };

  handleRequestApproval = (e) => {
    acceptJoiningRequest(
      e.target.dataset.channelId,
      e.target.dataset.membershipId,
      this.handleJoiningManagerSuccess(e.target.dataset.membershipId),
      null,
    );
  };

  handleUpdateRequestCount = (isAccepted = false, acceptedInfo) => {
    if (isAccepted) {
      const searchParams = {
        query: '',
        retrievalID: null,
        searchType: '',
        paginationNumber: 0,
      };
      getChannels(searchParams, 'all', this.loadChannels);
      this.triggerSwitchChannel(
        parseInt(acceptedInfo.channelId, 10),
        acceptedInfo.channelSlug,
        this.state.chatChannels,
      );
    }

    this.setState((prevState) => {
      return {
        userRequestCount: prevState.userRequestCount - 1,
      };
    });
  };

  triggerActiveContent = (e) => {
    if (
      // Trying to open in new tab
      e.ctrlKey ||
      e.shiftKey ||
      e.metaKey || // apple
      (e.button && e.button === 1) // middle click, >IE9 + everyone else
    ) {
      return false;
    }
    const { target } = e;
    const content =
      target.dataset.content || target.parentElement.dataset.content;
    if (content) {
      e.preventDefault();
      e.stopPropagation();
      this.hideChannelList();

      const { activeChannelId, activeChannel } = this.state;

      if (content.startsWith('chat_channels/')) {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-user',
        });
        getContent(`/${content}/channel_info`, this.setActiveContent, null);
      } else if (content === 'sidecar-channel-request') {
        this.setActiveContent({
          data: {
            user: getCurrentUser(),
            channel: {
              id: target.dataset.channelId,
              name: target.dataset.channelName,
              status: target.dataset.channelStatus,
            },
          },
          handleJoiningRequest: this.handleJoiningRequest,
          type_of: 'channel-request',
        });
      } else if (content === 'sidecar-joining-request-manager') {
        this.setActiveContent({
          data: {},
          type_of: 'channel-request-manager',
          updateRequestCount: this.handleUpdateRequestCount,
        });
      } else if (content === 'sidecar_all') {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        this.setActiveContent({
          path: `/chat_channel_memberships/${activeChannel.id}/edit`,
          type_of: 'article',
        });
      } else if (content.startsWith('sidecar-content-plus-video')) {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        this.setActiveContent({
          path: target.href || target.parentElement.href,
          type_of: 'article',
        });
        this.setState({ videoPath: `/video_chats/${activeChannelId}` });
      } else if (content.startsWith('sidecar-video')) {
        this.setState({ videoPath: target.href || target.parentElement.href });
      } else if (
        content.startsWith('sidecar') ||
        content.startsWith('article')
      ) {
        // article is legacy which can be removed shortly
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        this.setActiveContent({
          path: target.href || target.parentElement.href,
          type_of: 'article',
        });
      } else if (target.dataset.content === 'exit') {
        this.setActiveContentState(activeChannelId, null);
        this.setState({
          fullscreenContent: null,
          expanded: window.innerWidth > NARROW_WIDTH_LIMIT,
        });
      } else if (target.dataset.content === 'fullscreen') {
        const mode =
          this.state.fullscreenContent === 'sidecar' ? null : 'sidecar';
        this.setState({
          fullscreenContent: mode,
          expanded: mode === null || window.innerWidth > WIDE_WIDTH_LIMIT,
        });
      } else if (target.dataset.content === 'chat_channel_setting') {
        this.setActiveContent({
          data: {},
          type_of: 'chat-channel-setting',
          activeMembershipId: activeChannel.id,
          handleLeavingChannel: this.handleLeavingChannel,
        });
      }
    }
    return false;
  };

  setActiveContentState = (channelId, state) => {
    this.setState((prevState) => ({
      activeContent: {
        ...prevState.activeContent,
        [channelId]: state,
      },
    }));
  };

  closeReportAbuseForm = () => {
    const { activeChannelId } = this.state;
    this.setActiveContentState(activeChannelId, null);
    this.setState({
      fullscreenContent: null,
      expanded: window.innerWidth > NARROW_WIDTH_LIMIT,
    });
  };

  setActiveContent = (response) => {
    const { activeChannelId } = this.state;
    this.setActiveContentState(activeChannelId, response);
    setTimeout(() => {
      document.getElementById('chat_activecontent').scrollTop = 0;
      document.getElementById('chat').scrollLeft = 1000;
    }, 3);
    setTimeout(() => {
      document.getElementById('chat_activecontent').scrollTop = 0;
      document.getElementById('chat').scrollLeft = 1000;
    }, 10);
  };

  handleChannelOpenSuccess = (response) => {
    this.setState(({ chatChannels }) => {
      const newChannelsObj = chatChannels.map((channel) => {
        if (parseInt(response.channel, 10) === channel.chat_channel_id) {
          return { ...channel, last_opened_at: new Date() };
        }
        return channel;
      });
      return { chatChannels: newChannelsObj };
    });
  };

  handleLeavingChannel = (leftChannelId) => {
    const { chatChannels } = this.state;
    this.triggerSwitchChannel(
      chatChannels[1].chat_channel_id,
      chatChannels[1].channel_modified_slug,
      chatChannels,
    );
    this.setState((prevState) => ({
      chatChannels: prevState.chatChannels.filter(
        (channel) => channel.id !== leftChannelId,
      ),
    }));
    this.setActiveContentState(chatChannels[1].chat_channel_id, null);
  };

  triggerChannelTypeFilter = (e) => {
    const { filterQuery } = this.state;
    const type = e.target.dataset.channelType;
    this.setState({
      channelTypeFilter: type,
      fetchingPaginatedChannels: false,
    });
    const filters = type === 'all' ? {} : { filters: `channel_type:${type}` };
    const searchParams = {
      query: filterQuery,
      retrievalID: null,
      searchType: '',
      paginationNumber: 0,
    };
    if (filterQuery && type !== 'direct') {
      searchParams.searchType = 'discoverable';
      getChannels(searchParams, filters, this.loadChannels);
    } else {
      getChannels(searchParams, filters, this.loadChannels);
    }
  };

  handleFailure = (err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    addSnackbarItem({ message: err, addCloseButton: true });
  };

  renderMessages = () => {
    const {
      activeChannelId,
      messages,
      showTimestamp,
      activeChannel,
      currentUserId,
    } = this.state;
    if (!messages[activeChannelId]) {
      return '';
    }
    if (messages[activeChannelId].length === 0 && activeChannel) {
      if (activeChannel.channel_type === 'direct') {
        return (
          <div className="chatmessage" style={{ color: 'grey' }}>
            <div className="chatmessage__body">
              You and{' '}
              <a href={`/${activeChannel.channel_modified_slug}`}>
                {activeChannel.channel_modified_slug}
              </a>{' '}
              are connected because you both follow each other. All interactions{' '}
              <em>
                <b>must</b>
              </em>{' '}
              abide by the <a href="/code-of-conduct">code of conduct</a>.
            </div>
          </div>
        );
      }
      if (activeChannel.channel_type === 'open') {
        return (
          <div className="chatmessage" style={{ color: 'grey' }}>
            <div className="chatmessage__body">
              You have joined {activeChannel.channel_name}! All interactions{' '}
              <em>
                <b>must</b>
              </em>{' '}
              abide by the <a href="/code-of-conduct">code of conduct</a>.
            </div>
          </div>
        );
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
          onContentTrigger={this.triggerActiveContent}
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
          onContentTrigger={this.triggerActiveContent}
          onDeleteMessageTrigger={this.triggerDeleteMessage}
          onEditMessageTrigger={this.triggerEditMessage}
          onReportMessageTrigger={this.triggerReportMessage}
        />
      ),
    );
  };
  triggerReportMessage = (messageId) => {
    const { activeChannelId, messages } = this.state;

    this.setActiveContent({
      data: messages[activeChannelId].find(
        (message) => message.id === messageId,
      ),
      type_of: 'message-report-abuse',
    });
  };
  triggerChannelFilter = (e) => {
    const { channelTypeFilter } = this.state;
    const filters =
      channelTypeFilter === 'all'
        ? {}
        : { filters: `channel_type:${channelTypeFilter}` };
    const searchParams = {
      query: e.target.value,
      retrievalID: null,
      searchType: '',
      paginationNumber: 0,
    };
    if (e.target.value) {
      searchParams.searchType = 'discoverable';
      getChannels(searchParams, filters, this.loadChannels);
    } else {
      getChannels(searchParams, filters, this.loadChannels);
    }
  };

  toggleExpand = () => {
    this.setState((prevState) => ({ expanded: !prevState.expanded }));
  };

  toggleSearchShowing = () => {
    if (!this.state.searchShowing) {
      setTimeout(() => {
        document.getElementById('chatchannelsearchbar').focus();
      }, 100);
    } else {
      const searchParams = {
        query: '',
        retrievalID: null,
        searchType: '',
        paginationNumber: 0,
      };
      getChannels(searchParams, 'all', this.loadChannels);
      this.setState({ filterQuery: '' });
    }
    this.setState({ searchShowing: !this.state.searchShowing });
  };

  renderChatChannels = () => {
    const { state } = this;
    if (state.showChannelsList) {
      const { notificationsPermission } = state;
      const notificationsButton = '';
      let notificationsState = '';
      let invitesButton = '';
      let joiningRequestButton = '';
      if (notificationsPermission === 'granted') {
        notificationsState = (
          <div className="chat_chatconfig chat_chatconfig--on">
            Notifications On
          </div>
        );
      } else if (notificationsPermission === 'denied') {
        notificationsState = (
          <div className="chat_chatconfig chat_chatconfig--off">
            Notifications Off
          </div>
        );
      }

      return (
        <div className="chat__channels">
          {notificationsButton}

          <input
            placeholder="Search Channels"
            onKeyUp={this.debouncedChannelFilter}
            id="chatchannelsearchbar"
            className="crayons-textfield"
            aria-label="Search Channels"
          />
          {invitesButton}
          {joiningRequestButton}
          <div className="chat__channeltypefilter">
            <ChannelFilterButton
              type="all"
              name="all"
              active={state.channelTypeFilter === 'all'}
              onClick={this.triggerChannelTypeFilter}
            />
            <ChannelFilterButton
              type="direct"
              name="direct"
              active={state.channelTypeFilter === 'direct'}
              onClick={this.triggerChannelTypeFilter}
            />
            <ChannelFilterButton
              type="invite_only"
              name="group"
              active={state.channelTypeFilter === 'invite_only'}
              onClick={this.triggerChannelTypeFilter}
            />
            <Button
              className="chat__channelssearchtoggle crayons-btn--ghost-dimmed p-2"
              aria-label="Toggle request manager"
              onClick={this.triggerActiveContent}
              data-content="sidecar-joining-request-manager"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 477.869 477.869"
                width="18"
                height="18"
              >
                <path d="M387.415 233.496c48.976-44.03 52.987-119.424 8.958-168.4C355.99 20.177 288.4 12.546 239.02 47.332c-53.83-38-128.264-25.15-166.254 28.68-34.86 49.393-27.26 117.054 17.69 157.483C34.606 262.935-.25 320.976.002 384.108v51.2a17.07 17.07 0 0 0 17.067 17.067h443.733a17.07 17.07 0 0 0 17.067-17.067v-51.2c.252-63.132-34.605-121.173-90.454-150.612zM307.2 59.842c47.062-.052 85.256 38.057 85.31 85.12.037 33.564-19.63 64.023-50.237 77.8-1.314.597-2.628 1.143-3.96 1.707a83.66 83.66 0 0 1-12.988 4.045c-.853.188-1.707.3-2.577.46-4.952.95-9.977 1.457-15.02 1.52-2.27 0-4.557-.17-6.827-.375-.853 0-1.707 0-2.56-.17a86.22 86.22 0 0 1-27.904-8.226c-.324-.154-.7-.137-1.024-.273-1.707-.82-3.413-1.536-4.932-2.458.137-.17.222-.358.358-.53a119.72 119.72 0 0 0 18.278-33.297l.53-1.434a120.38 120.38 0 0 0 4.523-17.562c.154-.87.273-1.707.4-2.645.987-6.067 1.506-12.2 1.553-18.347a120.04 120.04 0 0 0-1.553-18.313l-.4-2.645c-1.064-5.96-2.576-11.83-4.523-17.562l-.53-1.434c-4.282-12-10.453-23.24-18.278-33.297-.137-.17-.222-.358-.358-.53C277.45 63.83 292.2 59.843 307.2 59.842zM85.335 145.176c-.12-47.006 37.886-85.2 84.892-85.33a85.11 85.11 0 0 1 59.134 23.686l2.918 2.9a87.75 87.75 0 0 1 8.09 9.813c.75 1.058 1.434 2.185 2.133 3.277a83.95 83.95 0 0 1 6.263 11.52c.427.973.75 1.963 1.126 2.935a83.42 83.42 0 0 1 4.233 13.653c.12.512.154 1.024.256 1.553a80.34 80.34 0 0 1 0 32.119c-.102.53-.137 1.04-.256 1.553a83.23 83.23 0 0 1-4.233 13.653c-.375.973-.7 1.963-1.126 2.935a84.25 84.25 0 0 1-6.263 11.503c-.7 1.092-1.382 2.22-2.133 3.277a87.55 87.55 0 0 1-8.09 9.813 117.37 117.37 0 0 1-2.918 2.901c-6.9 6.585-14.877 11.962-23.57 15.906a49.35 49.35 0 0 1-4.198 1.707 85.84 85.84 0 0 1-12.663 3.925c-1.075.24-2.185.375-3.277.563a84.67 84.67 0 0 1-14.046 1.417h-1.877c-4.713-.08-9.412-.554-14.046-1.417-1.092-.188-2.202-.324-3.277-.563a85.8 85.8 0 0 1-12.663-3.925l-4.198-1.707c-30.534-13.786-50.173-44.166-50.212-77.667zM307.2 418.242H34.135V384.11c-.25-57.833 36.188-109.468 90.76-128.614 29.296 12.197 62.25 12.197 91.546 0a137.14 137.14 0 0 1 16.623 7.356c3.55 1.826 6.827 3.908 10.24 6.007 2.22 1.382 4.47 2.73 6.605 4.25 3.294 2.338 6.4 4.88 9.455 7.492l5.75 5.12c2.816 2.662 5.46 5.478 8.004 8.363 1.826 2.082 3.6 4.198 5.29 6.383 2.236 2.867 4.37 5.803 6.35 8.823 1.707 2.56 3.226 5.222 4.727 7.885 1.707 2.935 3.277 5.87 4.7 8.926s2.697 6.4 3.925 9.66c1.075 2.833 2.22 5.65 3.106 8.533 1.195 3.96 2.03 8.055 2.867 12.15.512 2.423 1.178 4.796 1.553 7.253 1.01 6.757 1.53 13.58 1.553 20.412v34.133zm136.534 0h-102.4V384.11c0-5.342-.307-10.633-.785-15.872-.137-1.536-.375-3.055-.546-4.59-.46-3.772-1-7.51-1.707-11.213l-.973-4.762c-.82-3.8-1.77-7.566-2.85-11.298l-1.058-3.686c-4.78-15.277-11.704-29.797-20.565-43.127l-.666-.973a168.96 168.96 0 0 0-9.404-12.646l-.12-.154c-3.413-4.232-7.117-8.346-11.008-12.237h.7a120.8 120.8 0 0 0 14.524 1.024h.94c4.496-.04 8.985-.33 13.45-.87 1.4-.17 2.782-.427 4.18-.65a117.43 117.43 0 0 0 10.752-2.167l3.055-.785a116.21 116.21 0 0 0 13.653-4.642c54.612 19.127 91.083 70.785 90.83 128.65v34.132z" />
              </svg>
              {this.state.userRequestCount > 0 ? (
                <span className="crayons-indicator crayons-indicator--accent crayons-indicator--bullet requests-badge">
                  {this.state.userRequestCount}
                </span>
              ) : null}
            </Button>
            {this.state.isTagModerator ? (
              <Button
                className="chat__channelssearchtoggle crayons-btn--ghost-dimmed p-2"
                aria-label="Toggle request manager"
                onClick={this.toggleModalCreateChannel}
                data-content="sidecar-joining-request-manager"
              >
                <svg
                  version="1.1"
                  id="Capa_1"
                  xmlns="http://www.w3.org/2000/svg"
                  x="0px"
                  y="0px"
                  width="18"
                  height="18"
                  viewBox="0 0 512 512"
                  style="enable-background:new 0 0 512 512;"
                >
                  <path
                    d="M492,236H276V20c0-11.046-8.954-20-20-20c-11.046,0-20,8.954-20,20v216H20c-11.046,0-20,8.954-20,20s8.954,20,20,20h216
                  v216c0,11.046,8.954,20,20,20s20-8.954,20-20V276h216c11.046,0,20-8.954,20-20C512,244.954,503.046,236,492,236z"
                  />
                </svg>
              </Button>
            ) : null}
            {this.state.openModal ? (
              <CreateChatModal
                toggleModalCreateChannel={this.toggleModalCreateChannel}
                handleCreateChannelSuccess={this.handleCreateChannelSuccess}
              />
            ) : (
              ''
            )}
          </div>
          <Channels
            activeChannelId={state.activeChannelId}
            chatChannels={state.chatChannels}
            unopenedChannelIds={state.unopenedChannelIds}
            handleSwitchChannel={this.handleSwitchChannel}
            channelsLoaded={state.channelsLoaded}
            filterQuery={state.filterQuery}
            expanded={state.expanded}
            aria-expanded={state.expanded}
            currentUserId={state.currentUserId}
            triggerActiveContent={this.triggerActiveContent}
          />
          {notificationsState}
        </div>
      );
    }
    return '';
  };

  toggleModalCreateChannel = () => {
    const { openModal } = this.state;
    this.setState({ openModal: !openModal });
  };

  navigateToChannelsList = () => {
    const chatContainer = document.getElementsByClassName(
      'chat__activechat',
    )[0];

    chatContainer.classList.add('chat__activechat--hidden');
  };

  handleCreateChannelSuccess = () => {
    this.toggleModalCreateChannel();
    const searchParams = {
      query: '',
      retrievalID: null,
      searchType: '',
      paginationNumber: 0,
    };
    getChannels(searchParams, {}, this.loadChannels);
  };

  handleMessageScroll = () => {
    const {
      allMessagesLoaded,
      messages,
      activeChannelId,
      messageOffset,
    } = this.state;

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
          this.addMoreMessages,
        );
        const curretPosition = this.scroller.scrollHeight;
        this.setState({ currentMessageLocation: curretPosition });
      }
    }
  };

  addMoreMessages = (res) => {
    const { chatChannelId, messages } = res;

    if (messages.length > 0) {
      this.setState((prevState) => ({
        messages: {
          [chatChannelId]: [...messages, ...prevState.messages[chatChannelId]],
        },
      }));
    } else {
      this.setState({ allMessagesLoaded: true });
    }
  };

  jumpBacktoBottom = () => {
    scrollToBottom();
    document
      .getElementById('jumpback_button')
      .classList.remove('chatchanneljumpback__hide');
  };

  handleDragOver = (event) => {
    event.preventDefault();
    event.currentTarget.classList.add('opacity-25');
  };

  handleDragExit = (event) => {
    event.preventDefault();
    event.currentTarget.classList.remove('opacity-25');
  };

  handleImageDrop = (event) => {
    event.preventDefault();
    const { files } = event.dataTransfer;
    event.currentTarget.classList.remove('opacity-25');
    processImageUpload(files, this.handleImageSuccess, this.handleImageFailure);
  };
  sendCanvasImage = (files) => {
    dragAndUpload([files], this.handleImageSuccess, this.handleImageFailure);
  };
  handleImageSuccess = (res) => {
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
  handleImageFailure = (e) => {
    addSnackbarItem({ message: e.message, addCloseButton: true });
  };
  handleDragHover(e) {
    e.preventDefault();
    const messageArea = document.getElementById('messagelist');
    messageArea.classList.add('opacity-25');
  }
  handleDragExit(e) {
    e.preventDefault();
    const messageArea = document.getElementById('messagelist');
    messageArea.classList.remove('opacity-25');
  }
  renderActiveChatChannel = (channelHeader) => {
    const { state } = this;
    const channelName = state.activeChannel
      ? state.activeChannel.channel_name
      : ' ';
    return (
      <div className="activechatchannel">
        <div className="activechatchannel__conversation">
          {channelHeader}
          <DragAndDropZone
            onDragOver={this.handleDragOver}
            onDragExit={this.handleDragExit}
            onDrop={this.handleImageDrop}
          >
            <div
              className="activechatchannel__messages"
              onScroll={this.handleMessageScroll}
              ref={(scroller) => {
                this.scroller = scroller;
              }}
              id="messagelist"
            >
              {this.renderMessages()}
              <div
                className="messagelist__sentinel"
                id="messagelist__sentinel"
              />
            </div>
          </DragAndDropZone>
          <div
            className="chatchanneljumpback chatchanneljumpback__hide"
            id="jumpback_button"
          >
            <Button
              className="chatchanneljumpback__messages crayons-btn--outlined"
              onClick={this.jumpBacktoBottom}
              tabIndex="0"
              onKeyUp={(e) => {
                if (e.keyCode === 13) this.jumpBacktoBottom();
              }}
            >
              Scroll to Bottom
            </Button>
          </div>
          {this.renderDeleteModal()}
          <div className="activechatchannel__alerts">
            <Alert showAlert={state.showAlert} />
          </div>
          {this.renderChannelMembersList()}
          <div className="activechatchannel__form">
            <Compose
              handleSubmitOnClick={this.handleSubmitOnClick}
              handleKeyDown={this.handleKeyDown}
              handleSubmitOnClickEdit={this.handleSubmitOnClickEdit}
              handleMention={this.handleMention}
              handleKeyUp={this.handleKeyUp}
              handleKeyDownEdit={this.handleKeyDownEdit}
              activeChannelId={state.activeChannelId}
              activeChannelName={channelName}
              startEditing={state.startEditing}
              markdownEdited={state.markdownEdited}
              editMessageMarkdown={state.activeEditMessage.markdown}
              handleEditMessageClose={this.handleEditMessageClose}
              handleFilePaste={this.handleFilePaste}
            />
          </div>
        </div>
        <Content
          onTriggerContent={this.triggerActiveContent}
          resource={state.activeContent[state.activeChannelId]}
          activeChannel={state.activeChannel}
          fullscreen={state.fullscreenContent === 'sidecar'}
          closeReportAbuseForm={this.closeReportAbuseForm}
        />
        <VideoContent
          videoPath={state.videoPath}
          onTriggerVideoContent={this.onTriggerVideoContent}
          fullscreen={state.fullscreenContent === 'video'}
        />
      </div>
    );
  };

  handleFilePaste = (e) => {
    if (!e.clipboardData || !e.clipboardData.items) {
      return;
    }
    const items = [];
    for (let i = 0; i < e.clipboardData.items.length; i++) {
      const item = e.clipboardData.items[i];
      if (item.kind !== 'file') {
        continue;
      }
      items.push(item);
    }
    if (items && items.length > 0) {
      processImageUpload(
        [items[0].getAsFile()],
        this.handleImageSuccess,
        this.handleImageFailure,
      );
    }
  };

  onTriggerVideoContent = (e) => {
    if (e.target.dataset.content === 'exit') {
      this.setState({
        videoPath: null,
        fullscreenContent: null,
        expanded: window.innerWidth > 600,
      });
    } else if (this.state.fullscreenContent === 'video') {
      this.setState({ fullscreenContent: null });
    } else {
      this.setState({
        fullscreenContent: 'video',
        expanded: window.innerWidth > WIDE_WIDTH_LIMIT,
      });
    }
  };

  handleMention = (e) => {
    const { activeChannel } = this.state;
    const mention = e.keyCode === 64;
    if (mention && activeChannel.channel_type !== 'direct') {
      const memberListElement = document.getElementById('mentionList');
      memberListElement.focus();
      this.setState({ showMemberlist: true });
    }
  };

  handleKeyUp = (e) => {
    const { startEditing, activeChannel, showMemberlist } = this.state;
    const enterPressed = e.keyCode === 13;
    if (enterPressed && showMemberlist)
      this.setState({ showMemberlist: false });
    if (activeChannel.channel_type !== 'direct') {
      if (startEditing) {
        this.setState({ markdownEdited: true });
      }
      if (!e.target.value.includes('@') && showMemberlist) {
        this.setState({ showMemberlist: false });
      } else {
        this.setQuery(e.target);
        this.listHighlightManager(e.keyCode);
      }
    }
  };

  setQuery = (e) => {
    const { showMemberlist } = this.state;
    if (showMemberlist) {
      const before = e.value.substring(0, e.selectionStart);
      const query = before.substring(
        before.lastIndexOf('@') + 1,
        e.selectionStart,
      );

      if (query.includes(' ') || before.lastIndexOf('@') < 0)
        this.setState({ showMemberlist: false });
      else {
        this.setState({ showMemberlist: true });
        this.setState({ memberFilterQuery: query });
      }
    }
  };

  addUserName = (e) => {
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
    el.dispatchEvent(new Event('input'));
    el.focus();
    this.setState({ showMemberlist: false });
  };

  listHighlightManager = (keyCode) => {
    const mentionList = document.getElementById('mentionList');
    const activeElement = document.getElementsByClassName(
      'active__message__list',
    )[0];
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

  getMentionedUsers = (message) => {
    const { channelUsers, activeChannelId, activeChannel } = this.state;
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

  renderChannelMembersList = () => {
    const {
      showMemberlist,
      activeChannelId,
      channelUsers,
      memberFilterQuery,
    } = this.state;

    const filterRegx = new RegExp(memberFilterQuery, 'gi');

    return (
      <div
        className={
          showMemberlist ? 'mention__list mention__visible' : 'mention__list'
        }
        id="mentionList"
        data-testid="mentionList"
      >
        {showMemberlist
          ? Object.values(channelUsers[activeChannelId])
              .filter((user) => user.username.match(filterRegx))
              .map((user) => (
                <div
                  key={user.username}
                  className="mention__user"
                  role="button"
                  onClick={this.addUserName}
                  tabIndex="0"
                  data-content={user.username}
                  onKeyUp={(e) => {
                    if (e.keyCode === 13) this.addUserName();
                  }}
                >
                  <img
                    className="mention__user__image"
                    src={user.profile_image}
                    alt={user.name}
                    style={!user.profile_image ? { display: 'none' } : ' '}
                  />
                  <span
                    style={{
                      padding: '3px 0px',
                      'font-size': '16px',
                    }}
                  >
                    {'@'}
                    {user.username}
                    <p>{user.name}</p>
                  </span>
                </div>
              ))
          : ' '}
      </div>
    );
  };

  handleEditMessageClose = () => {
    this.setState({
      startEditing: false,
      markdownEdited: false,
      activeEditMessage: { message: '', markdown: '' },
    });
  };

  renderDeleteModal = () => {
    const { showDeleteModal } = this.state;
    return (
      <div
        id="message"
        className={
          showDeleteModal
            ? 'message__delete__modal crayons-modal crayons-modal--s absolute'
            : 'message__delete__modal message__delete__modal__hide crayons-modal crayons-modal--s absolute'
        }
        aria-hidden={showDeleteModal}
        aria-label="delete confirmation"
        role="dialog"
      >
        <div className="crayons-modal__box">
          <div className="crayons-modal__box__body">
            <h3>Are you sure, you want to delete this message?</h3>
            <div className="delete-actions__container">
              <Button
                className="crayons-btn crayons-btn--danger message__delete__button"
                onClick={this.handleMessageDelete}
                tabIndex="0"
                onKeyUp={(e) => {
                  if (e.keyCode === 13) this.handleMessageDelete();
                }}
              >
                Delete
              </Button>
              <Button
                className="crayons-btn crayons-btn--secondary message__cancel__button"
                onClick={this.handleCloseDeleteModal}
                tabIndex="0"
                onKeyUp={(e) => {
                  if (e.keyCode === 13) this.handleCloseDeleteModal();
                }}
              >
                Cancel
              </Button>
            </div>
          </div>
        </div>
        <div className="crayons-modal__overlay" />
      </div>
    );
  };

  handleCloseDeleteModal = () => {
    this.setState({ showDeleteModal: false, messageDeleteId: null });
  };

  handleMessageDelete = () => {
    const { messageDeleteId } = this.state;
    deleteMessage(messageDeleteId);
    this.setState({ showDeleteModal: false });
  };

  handleJoiningRequest = (e) => {
    sendChannelRequest(
      e.target.dataset.channelId,
      this.handleJoiningRequestSuccess,
      this.handleFailure,
    );
  };

  handleJoiningRequestSuccess = () => {
    const { activeChannelId } = this.state;
    this.setActiveContentState(activeChannelId, null);
    this.setState({ fullscreenContent: null });
    this.toggleSearchShowing();
  };

  renderChannelBackNav = () => {
    return (
      <Button
        className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost active-channel__back-btn"
        onClick={this.navigateToChannelsList}
        onKeyUp={(e) => {
          if (e.keyCode === 13) this.navigateToChannelsList(e);
        }}
        tabIndex="0"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          width="24"
          height="24"
          className="crayons-icon"
        >
          <path d="M10.828 12l4.95 4.95-1.414 1.414L8 12l6.364-6.364 1.414 1.414z" />
        </svg>
      </Button>
    );
  };

  renderChannelHeaderInner = () => {
    const { activeChannel } = this.state;
    if (activeChannel.channel_type === 'direct') {
      return (
        <a
          href={`/${activeChannel.channel_username}`}
          className="active-channel__title"
          onClick={this.triggerActiveContent}
          data-content="sidecar-user"
        >
          {activeChannel.channel_modified_slug}
        </a>
      );
    }
    return (
      <a
        href="#/"
        onClick={this.triggerActiveContent}
        data-content="chat_channel_setting"
      >
        {activeChannel.channel_name}
      </a>
    );
  };

  renderChannelConfigImage = () => {
    const { activeContent, activeChannel, activeChannelId } = this.state;
    if (
      activeContent[activeChannelId] &&
      activeContent[activeChannelId].type_of
    ) {
      return '';
    }

    const path =
      activeChannel.channel_type === 'direct'
        ? `/${activeChannel.channel_username}`
        : `#`;

    const dataContent =
      activeChannel.channel_type === 'direct'
        ? 'sidecar-user'
        : `chat_channel_setting`;

    const contentLink =
      activeChannel.channel_type === 'direct'
        ? `/${activeChannel.channel_username}`
        : '#/';

    return (
      <a
        className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost"
        onClick={this.triggerActiveContent}
        onKeyUp={(e) => {
          if (e.keyCode === 13) this.triggerActiveContent(e);
        }}
        tabIndex="0"
        href={contentLink}
        data-content={dataContent}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          width="24"
          height="24"
          className="crayons-icon"
          data-content={dataContent}
        >
          <path
            data-content={dataContent}
            d="M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM11 7h2v2h-2V7zm0 4h2v6h-2v-6z"
          />
        </svg>
      </a>
    );
  };

  render() {
    const { state } = this;
    let channelHeader = <div className="active-channel__header">&nbsp;</div>;
    if (state.activeChannel) {
      channelHeader = (
        <div className="active-channel__header">
          {this.renderChannelBackNav()}
          {this.renderChannelHeaderInner()}
          {this.renderChannelConfigImage()}
        </div>
      );
    }
    let fullscreenMode = '';
    if (state.fullscreenContent === 'sidecar') {
      fullscreenMode = 'chat--content-visible-full';
    } else if (state.fullscreenContent === 'video') {
      fullscreenMode = 'chat--video-visible-full';
    }
    return (
      <div
        data-testid="chat"
        className={`chat chat--expanded
         chat--${
           state.videoPath ? 'video-visible' : 'video-not-visible'
         } chat--${
          state.activeContent[state.activeChannelId]
            ? 'content-visible'
            : 'content-not-visible'
        } ${fullscreenMode}`}
        data-no-instant
        aria-expanded={state.expanded}
      >
        {this.renderChatChannels()}
        <div data-testid="active-chat" className="chat__activechat">
          {this.renderActiveChatChannel(channelHeader)}
        </div>
      </div>
    );
  }
}
