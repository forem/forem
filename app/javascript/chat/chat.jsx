import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import ConfigImage from 'images/three-dots.svg';
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
import {
  hideMessages,
  scrollToBottom,
  setupObserver,
  setupNotifications,
  getNotificationState,
} from './util';
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
    chatChannels: PropTypes.array.isRequired,
    chatOptions: PropTypes.object.isRequired,
  };

  constructor(props) {
    super(props);
    const chatChannels = JSON.parse(this.props.chatChannels);
    const chatOptions = JSON.parse(this.props.chatOptions);
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
    };
  }

  componentDidMount() {
    this.state.chatChannels.forEach((channel, index) => {
      if (index < 3) {
        this.setupChannel(channel.chat_channel_id);
      }
      if (channel.channel_type === 'open') {
        this.subscribePusher(`open-channel-${channel.chat_channel_id}`);
      }
    });
    setupObserver(this.observerCallback);
    this.subscribePusher(
      `private-message-notifications-${window.currentUser.id}`,
    );
    if (this.state.activeChannelId) {
      sendOpen(this.state.activeChannelId, this.handleChannelOpenSuccess, null);
    }
    this.setState({
      notificationsPermission: getNotificationState(),
    });
    if (this.state.showChannelsList) {
      const filters =
        this.state.channelTypeFilter === 'all'
          ? {}
          : { filters: `channel_type:${this.state.channelTypeFilter}` };
      getChannels(
        '',
        this.state.activeChannelId,
        this.props,
        this.state.channelPaginationNum,
        filters,
        this.loadChannels,
      );
    }
    if (!this.state.isMobileDevice) {
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
    if (document.getElementById('messagelist')) {
      if (!this.state.scrolled) {
        scrollToBottom();
      }
    }
  }

  liveCoding = e => {
    if (this.state.activeContent != { type_of: 'code_editor' }) {
      const newActiveContent = this.state.activeContent;
      newActiveContent[this.state.activeChannelId] = { type_of: 'code_editor' };
      this.setState({ activeContent: newActiveContent });
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
    channels.filter(channel => channel.chat_channel_id === parseInt(id))[0];

  subscribePusher = channelName => {
    if (this.state.subscribedPusherChannels.includes(channelName)) {
    } else {
      setupPusher(this.props.pusherKey, {
        channelId: channelName,
        messageCreated: this.receiveNewMessage,
        channelCleared: this.clearChannel,
        redactUserMessages: this.redactUserMessages,
        channelError: this.channelError,
        liveCoding: this.liveCoding,
        videoCallInitiated: this.receiveVideoCall,
        videoCallEnded: this.receiveVideoCallHangup,
      });
      const subscriptions = this.state.subscribedPusherChannels;
      subscriptions.push(channelName);
      this.setState({ subscribedPusherChannels: subscriptions });
    }
  };

  loadChannels = (channels, query) => {
    if (this.state.activeChannelId && query.length === 0) {
      this.setupChannel(this.state.activeChannelId);
      this.setState({
        chatChannels: channels,
        scrolled: false,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: '',
        activeChannel:
          this.state.activeChannel ||
          this.filterForActiveChannel(channels, this.state.activeChannelId),
      });
    } else if (this.state.activeChannelId) {
      this.setupChannel(this.state.activeChannelId);
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
    channels.forEach((channel, index) => {
      if (index < 3) {
        this.setupChannel(channel.chat_channel_id);
      }
      if (channel.channel_type === 'invite_only') {
        this.subscribePusher(`presence-channel-${channel.chat_channel_id}`);
      }
    });
    document.getElementById('chatchannels__channelslist').scrollTop = 0;
  };

  loadPaginatedChannels = channels => {
    const currentChannels = this.state.chatChannels;
    const currentChannelIds = currentChannels.map(
      (channel, index) => channel.id,
    );
    const newChannels = currentChannels;
    channels.forEach((channel, index) => {
      if (!currentChannelIds.includes(channel.id)) {
        newChannels.push(channel);
      }
    });
    if (
      currentChannels.length === newChannels.length &&
      this.state.channelPaginationNum > 3
    ) {
      return;
    }
    this.setState({
      chatChannels: newChannels,
      fetchingPaginatedChannels: false,
      channelPaginationNum: this.state.channelPaginationNum + 1,
    });
  };

  setupChannel = channelId => {
    if (
      !this.state.messages[channelId] ||
      this.state.messages[channelId].length === 0 ||
      this.state.messages[channelId][0].reception_method === 'pushed'
    ) {
      getAllMessages(channelId, this.receiveAllMessages);
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

  channelError = error => {
    this.setState({
      subscribedPusherChannels: [],
    });
  };

  receiveAllMessages = res => {
    const { chatChannelId, messages } = res;
    const newMessages = { ...this.state.messages, [chatChannelId]: messages };
    this.setState({ messages: newMessages, scrolled: false });
  };

  receiveNewMessage = message => {
    const receivedChatChannelId = message.chat_channel_id;
    let newMessages = [];
    if (this.state.messages[receivedChatChannelId]) {
      newMessages = this.state.messages[receivedChatChannelId].slice();
      newMessages.push(message);
      if (newMessages.length > 150) {
        newMessages.shift();
      }
    }
    const newShowAlert =
      this.state.activeChannelId === receivedChatChannelId
        ? { showAlert: this.state.scrolled }
        : {};
    let newMessageChannelIndex = 0;
    let newMessageChannel = null;
    const newChannelsObj = this.state.chatChannels.map((channel, index) => {
      if (receivedChatChannelId === channel.chat_channel_id) {
        channel.channel_last_message_at = new Date();
        newMessageChannelIndex = index;
        newMessageChannel = channel;
      }
      return channel;
    });

    if (newMessageChannelIndex > 0) {
      newChannelsObj.splice(newMessageChannelIndex, 1);
      newChannelsObj.unshift(newMessageChannel);
    }

    if (receivedChatChannelId === this.state.activeChannelId) {
      sendOpen(receivedChatChannelId, this.handleChannelOpenSuccess, null);
    }
    this.setState({
      ...newShowAlert,
      chatChannels: newChannelsObj,
      messages: {
        ...this.state.messages,
        [receivedChatChannelId]: newMessages,
      },
    });
  };

  receiveVideoCall = callObj => {
    const incomingCalls = this.state.incomingVideoCallChannelIds;
    incomingCalls.push(callObj.channelId);
    this.setState({ incomingVideoCallChannelIds: incomingCalls });
  };

  receiveVideoCallHangup = () => {
    if (this.state.videoCallParticipants.size < 1) {
      this.setState({ activeVideoChannelId: null });
    }
  };

  redactUserMessages = res => {
    // This is shallow clone. This might cause a problem
    const clonedMessages = Object.assign({}, this.state.messages);
    const newMessages = hideMessages(clonedMessages, res.userId);
    this.setState({ messages: newMessages });
  };

  clearChannel = res => {
    const newMessages = { ...this.state.messages, [res.chat_channel_id]: [] };
    this.setState({ messages: newMessages });
  };

  handleChannelScroll = e => {
    if (
      this.state.fetchingPaginatedChannels ||
      this.state.chatChannels.length < 30
    ) {
      return;
    }
    const { target } = e;
    if (target.scrollTop + target.offsetHeight + 1800 > target.scrollHeight) {
      this.setState({ fetchingPaginatedChannels: true });

      const filters =
        this.state.channelTypeFilter === 'all'
          ? {}
          : { filters: `channel_type:${this.state.channelTypeFilter}` };
      getChannels(
        this.state.filterQuery,
        this.state.activeChannelId,
        this.props,
        this.state.channelPaginationNum,
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
    // should check if user has the privilege
    if (message.startsWith('/code')) {
      const newActiveContent = this.state.activeContent;
      newActiveContent[this.state.activeChannelId] = { type_of: 'code_editor' };
      this.setState({ activeContent: newActiveContent });
    } else if (message.startsWith('/call')) {
      this.setState({ activeVideoChannelId: this.state.activeChannelId });
      window.pusher
        .channel(`presence-channel-${this.state.activeChannelId}`)
        .trigger('client-initiatevideocall', {
          channelId: this.state.activeChannelId,
        });
    } else if (message.startsWith('/github')) {
      const args = message.split('/github ')[1].trim();
      const newActiveContent = this.state.activeContent;
      newActiveContent[this.state.activeChannelId] = {
        type_of: 'github',
        args,
      };
      this.setState({ activeContent: newActiveContent });
    } else if (message[0] === '/') {
      conductModeration(
        this.state.activeChannelId,
        message,
        this.handleSuccess,
        this.handleFailure,
      );
    } else {
      sendMessage(
        this.state.activeChannelId,
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
    this.setState({
      activeVideoChannelId: this.state.activeChannelId,
      incomingVideoCallChannelIds: [],
    });
  };

  hangupVideoCall = () => {
    window.pusher
      .channel(`presence-channel-${this.state.activeVideoChannelId}`)
      .trigger('client-endvideocall', {});
    this.setState({
      activeVideoChannelId: null,
    });
  };

  handleVideoParticipantChange = participants => {
    this.setState({ videoCallParticipants: participants });
  };

  toggleVideoSound = () => {
    this.setState({ soundOn: !this.state.soundOn });
  };

  toggleVideoVideo = () => {
    this.setState({ videoOn: !this.state.videoOn });
  };

  triggerSwitchChannel = (id, slug) => {
    this.setState({
      activeChannel: this.filterForActiveChannel(this.state.chatChannels, id),
      activeChannelId: parseInt(id),
      scrolled: false,
      showAlert: false,
    });
    this.setupChannel(id);
    window.history.replaceState(null, null, `/connect/${slug}`);
    if (!this.state.isMobileDevice) {
      document.getElementById('messageform').focus();
    }
    if (window.ga && ga.create) {
      ga('send', 'pageview', location.pathname + location.search);
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

  triggerNotificationRequest = e => {
    const context = this;
    Notification.requestPermission(permission => {
      if (permission === 'granted') {
        context.setState({ notificationsPermission: 'granted' });
        setupNotifications();
      }
    });
  };

  triggerActiveContent = e => {
    if (
      // Trying to open in new tab
      e.ctrlKey ||
      e.shiftKey ||
      e.metaKey || // apple
      (e.button && e.button == 1) // middle click, >IE9 + everyone else
    ) {
      return;
    }

    const { target } = e;
    if (target.dataset.content) {
      e.preventDefault();
      e.stopPropagation();

      const newActiveContent = this.state.activeContent;
      if (target.dataset.content.startsWith('chat_channels/')) {
        newActiveContent[this.state.activeChannelId] = {
          type_of: 'loading-user',
        };
        getContent(
          `/api/${target.dataset.content}`,
          this.setActiveContent,
          null,
        );
      } else if (target.dataset.content.startsWith('users/')) {
        newActiveContent[this.state.activeChannelId] = {
          type_of: 'loading-user',
        };
        getContent(
          `/api/${target.dataset.content}`,
          this.setActiveContent,
          null,
        );
      } else if (target.dataset.content.startsWith('articles/')) {
        newActiveContent[this.state.activeChannelId] = {
          type_of: 'loading-post',
        };
        getContent(
          `/api/${target.dataset.content}`,
          this.setActiveContent,
          null,
        );
      } else if (target.dataset.content === 'exit') {
        newActiveContent[this.state.activeChannelId] = null;
        this.setState({ activeContent: newActiveContent });
      }
    }
    return false;
  };

  setActiveContent = response => {
    const newActiveContent = this.state.activeContent;
    newActiveContent[this.state.activeChannelId] = response;
    this.setState({ activeContent: newActiveContent });
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
    const newChannelsObj = this.state.chatChannels.map(channel => {
      if (parseInt(response.channel) === channel.chat_channel_id) {
        channel.last_opened_at = new Date();
      }
      return channel;
    });
    this.setState({ chatChannels: newChannelsObj });
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
    const type = e.target.dataset.channelType;
    this.setState({
      channelTypeFilter: type,
      fetchingPaginatedChannels: false,
    });
    const filters = type === 'all' ? {} : { filters: `channel_type:${type}` };
    getChannels(
      this.state.filterQuery,
      null,
      this.props,
      0,
      filters,
      this.loadChannels,
    );
  };

  triggerNonChatView = e => {
    this.setState({ nonChatView: e.target.dataset.content });
  };

  triggerExitView = () => {
    this.setState({ nonChatView: null });
  };

  handleFailure = err => {
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
      return;
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
    const filters =
      this.state.channelTypeFilter === 'all'
        ? {}
        : { filters: `channel_type:${this.state.channelTypeFilter}` };
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
    this.setState({ expanded: !this.state.expanded });
  };

  renderChatChannels = () => {
    if (this.state.showChannelsList) {
      const { notificationsPermission } = this.state;
      let notificationsButton = '';
      let notificationsState = '';
      let invitesButton = '';
      if (notificationsPermission === 'waiting-permission') {
        notificationsButton = (
          <div>
            <button
              className="chat__notificationsbutton "
              onClick={this.triggerNotificationRequest}
            >
              Turn on Notifications
            </button>
          </div>
        );
      } else if (notificationsPermission === 'granted') {
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
      if (this.state.inviteChannels.length > 0) {
        invitesButton = (
          <div className="chat__channelinvitationsindicator">
            <button
              onClick={this.triggerNonChatView}
              data-content="invitations"
            >
              New Invitations!
            </button>
          </div>
        );
      }
      if (this.state.expanded) {
        return (
          <div className="chat__channels chat__channels--expanded">
            {notificationsButton}
            <button
              className="chat__channelstogglebutt"
              onClick={this.toggleExpand}
            >
              {'<'}
            </button>
            <input placeholder="Filter" onKeyUp={this.triggerChannelFilter} />
            {invitesButton}
            <div className="chat__channeltypefilter">
              <button
                data-channel-type="all"
                onClick={this.triggerChannelTypeFilter}
                className={`chat__channeltypefilterbutton chat__channeltypefilterbutton--${
                  this.state.channelTypeFilter === 'all' ? 'active' : 'inactive'
                }`}
              >
                all
              </button>
              <button
                data-channel-type="direct"
                onClick={this.triggerChannelTypeFilter}
                className={`chat__channeltypefilterbutton chat__channeltypefilterbutton--${
                  this.state.channelTypeFilter === 'direct'
                    ? 'active'
                    : 'inactive'
                }`}
              >
                direct
              </button>
              <button
                data-channel-type="invite_only"
                onClick={this.triggerChannelTypeFilter}
                className={`chat__channeltypefilterbutton chat__channeltypefilterbutton--${
                  this.state.channelTypeFilter === 'invite_only'
                    ? 'active'
                    : 'inactive'
                }`}
              >
                group
              </button>
            </div>
            <Channels
              activeChannelId={this.state.activeChannelId}
              chatChannels={this.state.chatChannels}
              handleSwitchChannel={this.handleSwitchChannel}
              channelsLoaded={this.state.channelsLoaded}
              filterQuery={this.state.filterQuery}
              expanded={this.state.expanded}
              incomingVideoCallChannelIds={
                this.state.incomingVideoCallChannelIds
              }
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
          >
            {'>'}
          </button>
          <Channels
            incomingVideoCallChannelIds={this.state.incomingVideoCallChannelIds}
            activeChannelId={this.state.activeChannelId}
            chatChannels={this.state.chatChannels}
            handleSwitchChannel={this.handleSwitchChannel}
            expanded={this.state.expanded}
          />
          {notificationsState}
        </div>
      );
    }
    return '';
  };

  renderActiveChatChannel = (channelHeader, incomingCall) => (
    <div className="activechatchannel">
      <div className="activechatchannel__conversation">
        {channelHeader}
        <div className="activechatchannel__messages" id="messagelist">
          {this.renderMessages()}
          {incomingCall}
          <div className="messagelist__sentinel" id="messagelist__sentinel" />
        </div>
        <div className="activechatchannel__alerts">
          <Alert showAlert={this.state.showAlert} />
        </div>
        <div className="activechatchannel__form">
          <Compose
            handleSubmitOnClick={this.handleSubmitOnClick}
            handleKeyDown={this.handleKeyDown}
            activeChannelId={this.state.activeChannelId}
          />
        </div>
      </div>
      <Content
        onTriggerContent={this.triggerActiveContent}
        resource={this.state.activeContent[this.state.activeChannelId]}
        activeChannelId={this.state.activeChannelId}
        activeChannel={this.state.activeChannel}
        pusherKey={this.props.pusherKey}
        githubToken={this.props.githubToken}
      />
    </div>
  );

  render() {
    const detectIOSSafariClass =
      navigator.userAgent.match(/iPhone/i) &&
      !navigator.userAgent.match('CriOS')
        ? ' chat--iossafari'
        : '';
    let channelHeader = <div className="activechatchannel__header">&nbsp;</div>;
    const currentChannel = this.state.activeChannel;
    let channelConfigImage = '';
    if (currentChannel) {
      let channelHeaderInner = '';
      if (currentChannel.channel_type === 'direct') {
        channelHeaderInner = (
          <a
            href={`/${currentChannel.channel_username}`}
            onClick={this.triggerActiveContent}
            data-content={`users/by_username?url=${currentChannel.channel_username}`}
          >
            {currentChannel.channel_modified_slug}
          </a>
        );
        channelConfigImage = (
          <img
            src={ConfigImage}
            onClick={this.triggerActiveContent}
            data-content={`users/by_username?url=${currentChannel.channel_username}`}
          />
        );
      } else {
        channelHeaderInner = (
          <a
            href={`/connect/${currentChannel.channel_modified_slug}`}
            onClick={this.triggerActiveContent}
            data-content={`chat_channels/${this.state.activeChannelId}`}
          >
            {currentChannel.channel_name}
          </a>
        );
        channelConfigImage = (
          <img
            src={ConfigImage}
            onClick={this.triggerActiveContent}
            data-content={`chat_channels/${this.state.activeChannelId}`}
          />
        );
      }
      if (
        this.state.activeContent[this.state.activeChannelId] &&
        this.state.activeContent[this.state.activeChannelId].type_of
      ) {
        channelConfigImage = '';
      }
      channelHeader = (
        <div className="activechatchannel__header">
          {channelHeaderInner} {channelConfigImage}
        </div>
      );
    }
    let vid = '';
    let incomingCall = '';
    if (this.state.activeVideoChannelId) {
      vid = (
        <Video
          activeChannelId={this.state.activeChannelId}
          onToggleSound={this.toggleVideoSound}
          onToggleVideo={this.toggleVideoVideo}
          soundOn={this.state.soundOn}
          videoOn={this.state.videoOn}
          onExit={this.hangupVideoCall}
          onParticipantChange={this.handleVideoParticipantChange}
        />
      );
    } else if (
      this.state.incomingVideoCallChannelIds.includes(
        this.state.activeChannelId,
      )
    ) {
      incomingCall = (
        <div
          className="activechatchannel__incomingcall"
          onClick={this.answerVideoCall}
        >
          👋 Incoming Video Call{' '}
        </div>
      );
    }
    let nonChatView = '';
    if (this.state.nonChatView) {
      nonChatView = (
        <View
          channels={this.state.inviteChannels}
          onViewExit={this.triggerExitView}
          onAcceptInvitation={this.handleInvitationAccept}
          onDeclineInvitation={this.handleInvitationDecline}
        />
      );
    }
    return (
      <div
        className={`chat chat--${
          this.state.expanded ? 'expanded' : 'contracted'
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
