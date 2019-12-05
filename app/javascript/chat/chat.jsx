import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import ConfigImage from '../../assets/images/three-dots.svg';
import {
  conductModeration,
  getAllMessages,
  sendMessage,
  sendOpen,
  getChannels,
  getContent,
  getChannelInvites,
  sendChannelInviteAction,
} from './actions';
import { hideMessages, scrollToBottom, setupObserver } from './util';
import Alert from './alert';
import Channels from './channels';
import Compose from './compose';
import Message from './message';
import Content from './content';
import Video from './video';
import View from './view';

import setupPusher from '../src/utils/pusher';

export default class Chat extends Component {
  static propTypes = {
    pusherKey: PropTypes.number.isRequired,
    chatChannels: PropTypes.string.isRequired,
    chatOptions: PropTypes.string.isRequired,
    githubToken: PropTypes.string.isRequired,
  };

  constructor(props) {
    super(props);
    const chatChannels = JSON.parse(props.chatChannels);
    const chatOptions = JSON.parse(props.chatOptions);
    this.state = {
      messages: [],
      scrolled: false,
      showAlert: false,
      chatChannels,
      filterQuery: '',
      channelTypeFilter: 'all',
      channelsLoaded: false,
      channelPaginationNum: 0,
      fetchingPaginatedChannels: false,
      activeChannelId: chatOptions.activeChannelId,
      activeChannel: null,
      showChannelsList: chatOptions.showChannelsList,
      showTimestamp: chatOptions.showTimestamp,
      notificationsPermission: null,
      activeContent: {},
      expanded: window.innerWidth > 600,
      isMobileDevice: typeof window.orientation !== 'undefined',
      subscribedPusherChannels: [],
      activeVideoChannelId: null,
      incomingVideoCallChannelIds: [],
      videoCallParticipants: [],
      nonChatView: null,
      inviteChannels: [],
      soundOn: true,
      videoOn: true,
      messageOffset: 0,
      allMessagesLoaded: false,
      currentMessageLocation: 0,
    };
  }

  componentDidMount() {
    const {
      chatChannels,
      activeChannelId,
      showChannelsList,
      channelTypeFilter,
      isMobileDevice,
      channelPaginationNum,
    } = this.state;

    this.setupChannels(chatChannels);
    const channelsForPusherSub = chatChannels.filter(
      this.channelTypeFilter('open'),
    );
    this.subscribeChannelsToPusher(
      channelsForPusherSub,
      channel => `open-channel-${channel.chat_channel_id}`,
    );
    setupObserver(this.observerCallback);
    this.subscribePusher(
      `private-message-notifications-${window.currentUser.id}`,
    );
    if (activeChannelId) {
      sendOpen(activeChannelId, this.handleChannelOpenSuccess, null);
    }
    if (showChannelsList) {
      const filters =
        channelTypeFilter === 'all'
          ? {}
          : { filters: `channel_type:${channelTypeFilter}` };
      getChannels(
        '',
        activeChannelId,
        this.props,
        channelPaginationNum,
        filters,
        this.loadChannels,
      );
    }
    if (!isMobileDevice) {
      document.getElementById('messageform').focus();
    }
    if (document.getElementById('chatchannels__channelslist')) {
      document
        .getElementById('chatchannels__channelslist')
        .addEventListener('scroll', this.handleChannelScroll);
    }
    getChannelInvites(this.handleChannelInvites, null);
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

  liveCoding = e => {
    const { activeContent, activeChannelId } = this.state;
    if (activeContent !== { type_of: 'code_editor' }) {
      activeContent[activeChannelId] = { type_of: 'code_editor' };
      this.setState({ activeContent });
    }
    if (document.querySelector('.CodeMirror')) {
      const cm = document.querySelector('.CodeMirror').CodeMirror;
      if (cm && e.context === 'initializing-live-code-channel') {
        window.pusher.channel(e.channel).trigger('client-livecode', {
          value: cm.getValue(),
          cursorPos: cm.getCursor(),
        });
      } else if ((cm && e.keyPressed === true) || e.value.length > 0) {
        const cursorCoords = e.cursorPos;
        const cursorElement = document.createElement('span');
        cursorElement.classList.add('cursorelement');
        cursorElement.style.height = `${cursorCoords.bottom -
          cursorCoords.top}px`;
        cm.setValue(e.value);
        cm.setBookmark(e.cursorPos, { widget: cursorElement });
      }
    }
  };

  filterForActiveChannel = (channels, id) =>
    channels.filter(channel => channel.chat_channel_id === parseInt(id, 10))[0];

  subscribePusher = channelName => {
    const { subscribedPusherChannels } = this.state;
    const { pusherKey } = this.props;
    if (!subscribedPusherChannels.includes(channelName)) {
      setupPusher(pusherKey, {
        channelId: channelName,
        messageCreated: this.receiveNewMessage,
        channelCleared: this.clearChannel,
        redactUserMessages: this.redactUserMessages,
        channelError: this.channelError,
        liveCoding: this.liveCoding,
        videoCallInitiated: this.receiveVideoCall,
        videoCallEnded: this.receiveVideoCallHangup,
      });
      const subscriptions = subscribedPusherChannels;
      subscriptions.push(channelName);
      this.setState({ subscribedPusherChannels: subscriptions });
    }
  };

  loadChannels = (channels, query) => {
    const { activeChannelId, activeChannel } = this.state;
    if (activeChannelId && query.length === 0) {
      this.setupChannel(activeChannelId);
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
    } else if (activeChannelId) {
      this.setupChannel(activeChannelId);
      this.setState({
        scrolled: false,
        chatChannels: channels,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query,
      });
    } else if (channels.length > 0) {
      this.setState({
        chatChannels: channels,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query || '',
        scrolled: false,
      });
      const channel = channels[0];
      this.triggerSwitchChannel(
        channel.chat_channel_id,
        channel.channel_modified_slug,
      );
    } else {
      this.setState({ channelsLoaded: true });
    }
    this.subscribeChannelsToPusher(
      channels.filter(this.channelTypeFilter('invite_only')),
      channel => `presence-channel-${channel.chat_channel_id}`,
    );
    document.getElementById('chatchannels__channelslist').scrollTop = 0;
  };

  subscribeChannelsToPusher = (channels, channelNameFn) => {
    channels.forEach(channel => {
      this.subscribePusher(channelNameFn(channel));
    });
  };

  channelTypeFilter = type => channel => {
    return channel.channel_type === type;
  };

  setupChannels = channels => {
    channels.forEach((channel, index) => {
      if (index < 3) {
        this.setupChannel(channel.chat_channel_id);
      }
    });
  };

  loadPaginatedChannels = channels => {
    const { state } = this.state;
    const currentChannels = state.chatChannels;
    const currentChannelIds = currentChannels.map(channel => channel.id);
    const newChannels = currentChannels;
    channels.forEach(channel => {
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

  setupChannel = channelId => {
    const { messages, messageOffset } = this.state;
    if (
      !messages[channelId] ||
      messages[channelId].length === 0 ||
      messages[channelId][0].reception_method === 'pushed'
    ) {
      getAllMessages(channelId, messageOffset, this.receiveAllMessages);
    }
    this.subscribePusher(`presence-channel-${channelId}`);
  };

  observerCallback = entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.setState({ scrolled: false, showAlert: false });
      } else {
        this.setState({ scrolled: true });
      }
    });
  };

  channelError = _error => {
    this.setState({
      subscribedPusherChannels: [],
    });
  };

  receiveAllMessages = res => {
    const { chatChannelId, messages } = res;
    this.setState(prevState => ({
      messages: { ...prevState.messages, [chatChannelId]: messages },
      scrolled: false,
    }));
  };

  receiveNewMessage = message => {
    const { messages, activeChannelId, scrolled, chatChannels } = this.state;
    const receivedChatChannelId = message.chat_channel_id;
    let newMessages = [];
    if (messages[receivedChatChannelId]) {
      newMessages = messages[receivedChatChannelId].slice();
      newMessages.push(message);
      if (newMessages.length > 150) {
        newMessages.shift();
      }
    }
    const newShowAlert =
      activeChannelId === receivedChatChannelId ? { showAlert: scrolled } : {};
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

    if (receivedChatChannelId === activeChannelId) {
      sendOpen(receivedChatChannelId, this.handleChannelOpenSuccess, null);
    }
    this.setState(prevState => ({
      ...newShowAlert,
      chatChannels: newChannelsObj,
      messages: {
        ...prevState.messages,
        [receivedChatChannelId]: newMessages,
      },
    }));
  };

  receiveVideoCall = callObj => {
    this.setState(prevState => ({
      incomingVideoCallChannelIds: [...prevState, callObj.channelId],
    }));
  };

  receiveVideoCallHangup = () => {
    const { videoCallParticipants } = this.state;
    if (videoCallParticipants.size < 1) {
      this.setState({ activeVideoChannelId: null });
    }
  };

  redactUserMessages = res => {
    const { messages } = this.state;
    const newMessages = hideMessages(messages, res.userId);
    this.setState({ messages: newMessages });
  };

  clearChannel = res => {
    this.setState(prevState => ({
      messages: { ...prevState.messages, [res.chat_channel_id]: [] },
    }));
  };

  handleChannelScroll = e => {
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
      getChannels(
        filterQuery,
        activeChannelId,
        this.props,
        channelPaginationNum,
        filters,
        this.loadPaginatedChannels,
      );
    }
  };

  handleChannelInvites = response => {
    this.setState({ inviteChannels: response });
  };

  handleKeyDown = e => {
    const enterPressed = e.keyCode === 13;
    const targetValue = e.target.value;
    const messageIsEmpty = targetValue.length === 0;
    const shiftPressed = e.shiftKey;

    if (enterPressed) {
      if (messageIsEmpty) {
        e.preventDefault();
      } else if (!messageIsEmpty && !shiftPressed) {
        e.preventDefault();
        this.handleMessageSubmit(e.target.value);
        e.target.value = '';
      }
    }
  };

  handleMessageSubmit = message => {
    const { activeChannelId } = this.state;
    // should check if user has the privilege
    if (message.startsWith('/code')) {
      this.setActiveContentState(activeChannelId, { type_of: 'code_editor' });
    } else if (message.startsWith('/call')) {
      this.setState({ activeVideoChannelId: activeChannelId });
      window.pusher
        .channel(`presence-channel-${activeChannelId}`)
        .trigger('client-initiatevideocall', {
          channelId: activeChannelId,
        });
    } else if (message.startsWith('/github')) {
      const args = message.split('/github ')[1].trim();
      this.setActiveContentState(activeChannelId, { type_of: 'github', args });
    } else if (message[0] === '/') {
      conductModeration(
        activeChannelId,
        message,
        this.handleSuccess,
        this.handleFailure,
      );
    } else {
      sendMessage(
        activeChannelId,
        message,
        this.handleSuccess,
        this.handleFailure,
      );
    }
  };

  handleSwitchChannel = e => {
    e.preventDefault();
    let { target } = e;
    if (!target.dataset.channelId) {
      target = target.parentElement;
    }
    this.triggerSwitchChannel(
      target.dataset.channelId,
      target.dataset.channelSlug,
    );
  };

  answerVideoCall = () => {
    const { activeChannelId } = this.state;
    this.setState({
      activeVideoChannelId: activeChannelId,
      incomingVideoCallChannelIds: [],
    });
  };

  hangupVideoCall = () => {
    const { activeVideoChannelId } = this.state;
    window.pusher
      .channel(`presence-channel-${activeVideoChannelId}`)
      .trigger('client-endvideocall', {});
    this.setState({
      activeVideoChannelId: null,
    });
  };

  handleVideoParticipantChange = participants => {
    this.setState({ videoCallParticipants: participants });
  };

  toggleVideoSound = () => {
    this.setState(prevState => ({ soundOn: !prevState.soundOn }));
  };

  toggleVideoVideo = () => {
    this.setState(prevState => ({ videoOn: !prevState.videoOn }));
  };

  triggerSwitchChannel = (id, slug) => {
    const { chatChannels, isMobileDevice } = this.state;
    this.setState({
      activeChannel: this.filterForActiveChannel(chatChannels, id),
      activeChannelId: parseInt(id, 10),
      scrolled: false,
      showAlert: false,
    });
    this.setupChannel(id);
    window.history.replaceState(null, null, `/connect/${slug}`);
    if (!isMobileDevice) {
      document.getElementById('messageform').focus();
    }
    if (window.ga && ga.create) {
      ga('send', 'pageview', window.location.pathname + window.location.search);
    }
    sendOpen(id, this.handleChannelOpenSuccess, null);
  };

  handleSubmitOnClick = e => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      this.handleMessageSubmit(message);
      document.getElementById('messageform').value = '';
    }
  };

  handleSuccess = response => {
    if (response.status === 'error') {
      this.receiveNewMessage(response.message);
    }
  };

  triggerActiveContent = e => {
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
    if (target.dataset.content) {
      e.preventDefault();
      e.stopPropagation();

      const { activeChannelId } = this.state;
      if (target.dataset.content.startsWith('chat_channels/')) {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-user',
        });
        getContent(
          `/api/${target.dataset.content}`,
          this.setActiveContent,
          null,
        );
      } else if (target.dataset.content.startsWith('users/')) {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-user',
        });
        getContent(
          `/api/${target.dataset.content}`,
          this.setActiveContent,
          null,
        );
      } else if (target.dataset.content.startsWith('articles/')) {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        getContent(
          `/api/${target.dataset.content}`,
          this.setActiveContent,
          null,
        );
      } else if (target.dataset.content === 'exit') {
        this.setActiveContentState(activeChannelId, null);
      }
    }
    return false;
  };

  setActiveContentState = (channelId, state) => {
    this.setState(prevState => ({
      activeContent: {
        ...prevState.activeContent,
        [channelId]: state,
      },
    }));
  };

  setActiveContent = response => {
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

  handleChannelOpenSuccess = response => {
    this.setState(({ chatChannels }) => {
      const newChannelsObj = chatChannels.map(channel => {
        if (parseInt(response.channel, 10) === channel.chat_channel_id) {
          return { ...channel, last_opened_at: new Date() };
        }
        return channel;
      });
      return { chatChannels: newChannelsObj };
    });
  };

  handleInvitationAccept = e => {
    const id = e.target.dataset.content;
    sendChannelInviteAction(id, 'accept', this.handleChannelInviteResult, null);
  };

  handleInvitationDecline = e => {
    const id = e.target.dataset.content;
    sendChannelInviteAction(
      id,
      'decline',
      this.handleChannelInviteResult,
      null,
    );
  };

  handleChannelInviteResult = response => {
    this.setState({ inviteChannels: response });
  };

  triggerChannelTypeFilter = e => {
    const { filterQuery } = this.state;
    const type = e.target.dataset.channelType;
    this.setState({
      channelTypeFilter: type,
      fetchingPaginatedChannels: false,
    });
    const filters = type === 'all' ? {} : { filters: `channel_type:${type}` };
    getChannels(filterQuery, null, this.props, 0, filters, this.loadChannels);
  };

  triggerNonChatView = e => {
    this.setState({ nonChatView: e.target.dataset.content });
  };

  triggerExitView = () => {
    this.setState({ nonChatView: null });
  };

  handleFailure = err => {
    // eslint-disable-next-line no-console
    console.error(err);
  };

  renderMessages = () => {
    const {
      activeChannelId,
      messages,
      showTimestamp,
      activeChannel,
    } = this.state;
    if (!messages[activeChannelId]) {
      return '';
    }
    if (messages[activeChannelId].length === 0 && activeChannel) {
      if (activeChannel.channel_type === 'direct') {
        return (
          <div className="chatmessage" style={{ color: 'grey' }}>
            <div className="chatmessage__body">
              You and
              {' '}
              <a href={`/${activeChannel.channel_modified_slug}`}>
                {activeChannel.channel_modified_slug}
              </a>
              {' '}
              are connected because you both follow each other. All interactions
              {' '}
              <em>
                <b>must</b>
              </em>
              {' '}
              abide by the 
              {' '}
              <a href="/code-of-conduct">code of conduct</a>
.
            </div>
          </div>
        );
      }
      if (activeChannel.channel_type === 'open') {
        return (
          <div className="chatmessage" style={{ color: 'grey' }}>
            <div className="chatmessage__body">
              You have joined 
              {' '}
              {activeChannel.channel_name}
! All interactions
              {' '}
              <em>
                <b>must</b>
              </em>
              {' '}
              abide by the 
              {' '}
              <a href="/code-of-conduct">code of conduct</a>
.
            </div>
          </div>
        );
      }
    }
    return messages[activeChannelId].map(message => (
      <Message
        user={message.username}
        userID={message.user_id}
        profileImageUrl={message.profile_image_url}
        message={message.message}
        timestamp={showTimestamp ? message.timestamp : null}
        color={message.color}
        type={message.type}
        onContentTrigger={this.triggerActiveContent}
      />
    ));
  };

  triggerChannelFilter = e => {
    const { channelTypeFilter } = this.state;
    const filters =
      channelTypeFilter === 'all'
        ? {}
        : { filters: `channel_type:${channelTypeFilter}` };
    getChannels(
      e.target.value,
      null,
      this.props,
      0,
      filters,
      this.loadChannels,
    );
  };

  toggleExpand = () => {
    this.setState(prevState => ({ expanded: !prevState.expanded }));
  };

  renderChannelFilterButton = (type, name, active) => (
    <button
      data-channel-type={type}
      onClick={this.triggerChannelTypeFilter}
      className={`chat__channeltypefilterbutton chat__channeltypefilterbutton--${
        type === active ? 'active' : 'inactive'
      }`}
      type="button"
    >
      {name}
    </button>
  );

  renderChatChannels = () => {
    const { state } = this;
    if (state.showChannelsList) {
      const { notificationsPermission } = state;
      const notificationsButton = '';
      let notificationsState = '';
      let invitesButton = '';
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
      if (state.inviteChannels.length > 0) {
        invitesButton = (
          <div className="chat__channelinvitationsindicator">
            <button
              onClick={this.triggerNonChatView}
              data-content="invitations"
              type="button"
            >
              New Invitations!
            </button>
          </div>
        );
      }
      if (state.expanded) {
        return (
          <div className="chat__channels chat__channels--expanded">
            {notificationsButton}
            <button
              className="chat__channelstogglebutt"
              onClick={this.toggleExpand}
              type="button"
            >
              {'<'}
            </button>
            <input placeholder="Filter" onKeyUp={this.triggerChannelFilter} />
            {invitesButton}
            <div className="chat__channeltypefilter">
              {this.renderChannelFilterButton(
                'all',
                'all',
                state.channelTypeFilter,
              )}
              {this.renderChannelFilterButton(
                'direct',
                'direct',
                state.channelTypeFilter,
              )}
              {this.renderChannelFilterButton(
                'invite_only',
                'group',
                state.channelTypeFilter,
              )}
            </div>
            <Channels
              activeChannelId={state.activeChannelId}
              chatChannels={state.chatChannels}
              handleSwitchChannel={this.handleSwitchChannel}
              channelsLoaded={state.channelsLoaded}
              filterQuery={state.filterQuery}
              expanded={state.expanded}
              incomingVideoCallChannelIds={state.incomingVideoCallChannelIds}
            />
            {notificationsState}
          </div>
        );
      }
      return (
        <div className="chat__channels">
          {notificationsButton}
          <button
            className="chat__channelstogglebutt"
            onClick={this.toggleExpand}
            style={{ width: '100%' }}
            type="button"
          >
            {'>'}
          </button>
          <Channels
            incomingVideoCallChannelIds={state.incomingVideoCallChannelIds}
            activeChannelId={state.activeChannelId}
            chatChannels={state.chatChannels}
            handleSwitchChannel={this.handleSwitchChannel}
            expanded={state.expanded}
          />
          {notificationsState}
        </div>
      );
    }
    return '';
  };

  handleMessageScroll = () => {
    const {
      allMessagesLoaded,
      messages,
      activeChannelId,
      messageOffset,
    } = this.state;

    const jumpbackButton = document.getElementById('jumpback_button');

    if (this.scroller) {
      const scrolledRatio =
        (this.scroller.scrollTop + this.scroller.clientHeight) /
        this.scroller.scrollHeight;

      if (scrolledRatio < 0.7) {
        jumpbackButton.classList.remove('chatchanneljumpback__hide');
      } else if (scrolledRatio > 0.8) {
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

  addMoreMessages = res => {
    const { chatChannelId, messages } = res;

    if (messages.length > 0) {
      this.setState(prevState => ({
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

  renderActiveChatChannel = (channelHeader, incomingCall) => {
    const { state, props } = this;
    return (
      <div className="activechatchannel">
        <div className="activechatchannel__conversation">
          {channelHeader}
          <div
            className="activechatchannel__messages"
            onScroll={this.handleMessageScroll}
            ref={scroller => {
              this.scroller = scroller;
            }}
            id="messagelist"
          >
            {this.renderMessages()}
            {incomingCall}
            <div className="messagelist__sentinel" id="messagelist__sentinel" />
          </div>
          <div
            className="chatchanneljumpback chatchanneljumpback__hide"
            id="jumpback_button"
          >
            <div
              role="button"
              className="chatchanneljumpback__messages"
              onClick={this.jumpBacktoBottom}
              tabIndex="0"
              onKeyUp={e => {
                if (e.keyCode === 13) this.jumpBacktoBottom();
              }}
            >
              Scroll to Bottom
            </div>
          </div>
          <div className="activechatchannel__alerts">
            <Alert showAlert={state.showAlert} />
          </div>
          <div className="activechatchannel__form">
            <Compose
              handleSubmitOnClick={this.handleSubmitOnClick}
              handleKeyDown={this.handleKeyDown}
              activeChannelId={state.activeChannelId}
            />
          </div>
        </div>
        <Content
          onTriggerContent={this.triggerActiveContent}
          resource={state.activeContent[state.activeChannelId]}
          activeChannelId={state.activeChannelId}
          activeChannel={state.activeChannel}
          pusherKey={props.pusherKey}
          githubToken={props.githubToken}
        />
      </div>
    );
  };

  renderChannelHeaderInner = () => {
    const { activeChannel, activeChannelId } = this.state;
    if (activeChannel.channel_type === 'direct') {
      return (
        <a
          href={`/${activeChannel.channel_username}`}
          onClick={this.triggerActiveContent}
          data-content={`users/by_username?url=${activeChannel.channel_username}`}
        >
          {activeChannel.channel_modified_slug}
        </a>
      );
    }
    return (
      <a
        href={`/connect/${activeChannel.channel_modified_slug}`}
        onClick={this.triggerActiveContent}
        data-content={`chat_channels/${activeChannelId}`}
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

    const dataContent =
      activeChannel.channel_type === 'direct'
        ? `users/by_username?url=${activeChannel.channel_username}`
        : `chat_channels/${activeChannelId}`;

    return (
      <div
        className="activechatchannel__channelconfig"
        onClick={this.triggerActiveContent}
        onKeyUp={e => {
          if (e.keyCode === 13) this.triggerActiveContent(e);
        }}
        role="button"
        tabIndex="0"
        data-content={dataContent}
      >
        <img
          src={ConfigImage}
          alt="channel config"
          data-content={dataContent}
        />
      </div>
    );
  };

  render() {
    const { state } = this;
    const detectIOSSafariClass =
      navigator.userAgent.match(/iPhone/i) &&
      !navigator.userAgent.match('CriOS')
        ? ' chat--iossafari'
        : '';
    let channelHeader = <div className="activechatchannel__header">&nbsp;</div>;
    if (state.activeChannel) {
      channelHeader = (
        <div className="activechatchannel__header">
          {this.renderChannelHeaderInner()}
          {this.renderChannelConfigImage()}
        </div>
      );
    }
    let vid = '';
    let incomingCall = '';
    if (state.activeVideoChannelId) {
      vid = (
        <Video
          activeChannelId={state.activeChannelId}
          onToggleSound={this.toggleVideoSound}
          onToggleVideo={this.toggleVideoVideo}
          soundOn={state.soundOn}
          videoOn={state.videoOn}
          onExit={this.hangupVideoCall}
          onParticipantChange={this.handleVideoParticipantChange}
        />
      );
    } else if (
      state.incomingVideoCallChannelIds.includes(state.activeChannelId)
    ) {
      incomingCall = (
        <div
          className="activechatchannel__incomingcall"
          onClick={this.answerVideoCall}
          onKeyUp={e => {
            if (e.keyCode === 13) this.answerVideoCall();
          }}
          role="button"
          tabIndex="0"
        >
          <span role="img" aria-label="waving">
            👋
          </span>
          {' '}
          Incoming Video Call
          {' '}
        </div>
      );
    }
    let nonChatView = '';
    if (state.nonChatView) {
      nonChatView = (
        <View
          channels={state.inviteChannels}
          onViewExit={this.triggerExitView}
          onAcceptInvitation={this.handleInvitationAccept}
          onDeclineInvitation={this.handleInvitationDecline}
        />
      );
    }
    return (
      <div
        className={`chat chat--${
          state.expanded ? 'expanded' : 'contracted'
        }${detectIOSSafariClass}`}
        data-no-instant
      >
        {this.renderChatChannels()}
        <div className="chat__activechat">
          {vid}
          {nonChatView}
          {this.renderActiveChatChannel(channelHeader, incomingCall)}
        </div>
      </div>
    );
  }
}
