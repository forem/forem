import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { conductModeration, getAllMessages, sendMessage, sendOpen, getChannels, getContent } from './actions';
import { hideMessages, scrollToBottom, setupObserver, setupNotifications, getNotificationState } from './util';
import Alert from './alert';
import Channels from './channels';
import Compose from './compose';
import Message from './message';
import Content from './content';
import Video from './video';

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
      isMobileDevice: typeof window.orientation !== "undefined",
      subscribedPusherChannels: [],
      activeVideoChannelId: null,
      incomingVideoCallChannelIds: []
    };
  }

  componentDidMount() {
    this.state.chatChannels.forEach((channel, index) => {
      if ( index < 3 ) {
        this.setupChannel(channel.id);
      }
      if (channel.channel_type === "open") {
        this.subscribePusher(`open-channel-${channel.id}`)
      }
    });
    setupObserver(this.observerCallback);
    this.subscribePusher(`private-message-notifications-${window.currentUser.id}`)
    if (this.state.activeChannelId) {
      sendOpen(
        this.state.activeChannelId,
        this.handleChannelOpenSuccess,
        null,
      );
    }
    this.setState({
      notificationsPermission: getNotificationState(),
    });
    if (this.state.showChannelsList) {
      const filters = this.state.channelTypeFilter === 'all' ? {} : {filters: 'channel_type:'+this.state.channelTypeFilter};
      getChannels('', this.state.activeChannelId, this.props, this.state.channelPaginationNum, filters, this.loadChannels);
    }
    if (!this.state.isMobileDevice) {
      document.getElementById("messageform").focus();
    }
    document.getElementById('chatchannels__channelslist').addEventListener('scroll', this.handleChannelScroll);
  }
  componentDidUpdate() {
    if (!this.state.scrolled) {
      scrollToBottom();
    }
  }

  liveCoding = e => {
    if (this.state.activeContent != {type_of: "code_editor"}) {
      let newActiveContent = this.state.activeContent
      newActiveContent[this.state.activeChannelId] = {type_of: "code_editor"}
      this.setState({activeContent: newActiveContent})
    }
    if (document.querySelector(".CodeMirror")) {
      let cm = document.querySelector(".CodeMirror").CodeMirror
      if (cm && e.context === 'initializing-live-code-channel') {
        window.pusher.channel(e.channel).trigger('client-livecode', {
          value: cm.getValue(),
          cursorPos: cm.getCursor(),
        });
      } else if (cm && e.keyPressed === true || e.value.length > 0) {
        const cursorCoords = e.cursorPos
        const cursorElement = document.createElement('span');
        cursorElement.classList.add("cursorelement")
        cursorElement.style.height = `${(cursorCoords.bottom - cursorCoords.top)}px`;
        cm.setValue(e.value);
        cm.setBookmark(e.cursorPos, { widget: cursorElement });
      }
    }
  }


  filterForActiveChannel = (channels, id) => {
    return channels.filter(channel => channel.id === parseInt(id))[0]
  }

  subscribePusher = channelName => {
    if (this.state.subscribedPusherChannels.includes(channelName)){
      return
    } else {
      setupPusher(this.props.pusherKey, {
        channelId: channelName,
        messageCreated: this.receiveNewMessage,
        channelCleared: this.clearChannel,
        redactUserMessages: this.redactUserMessages,
        channelError: this.channelError,
        liveCoding: this.liveCoding,
        videoCallInitiated: this.receiveVideoCall,
        videoCallEnded: this.receiveVideoCallHangup
      });
      let subscriptions = this.state.subscribedPusherChannels;
      subscriptions.push(channelName);
      this.setState({subscribedPusherChannels:subscriptions})
    }
  }

  loadChannels = (channels, query) => {
    if (this.state.activeChannelId && query.length === 0) {
      this.setupChannel(this.state.activeChannelId);
      this.setState({
        chatChannels: channels,
        scrolled: false,
        channelsLoaded: true,
        channelPaginationNum: 0,
        activeChannel: this.filterForActiveChannel(channels, this.state.activeChannelId)
      });
    } if (this.state.activeChannelId) {
      this.setupChannel(this.state.activeChannelId);
      this.setState({
        scrolled: false,
        chatChannels: channels,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query
      });
    } else if (channels.length > 0) {
      this.setState({
        chatChannels: channels,
        channelsLoaded: true,
        channelPaginationNum: 0,
        scrolled: false,
      });
      const channel = channels[0]
      const channelSlug = channel.channel_type === 'direct' ?
        '@'+channel.slug.replace(`${window.currentUser.username}/`, '').replace(`/${window.currentUser.username}`, '') :
        channel.slug
      this.triggerSwitchChannel(channel.id, channelSlug);
    } else {
      this.setState({channelsLoaded: true})
    }
    channels.forEach((channel, index) => {
      if ( index < 3 ) {
        this.setupChannel(channel.id);
      }
      if (channel.channel_type === "invite_only"){
        this.subscribePusher(`presence-channel-${channel.id}`)
      }
    });
  }

  loadPaginatedChannels = (channels) => {
    const currentChannels = this.state.chatChannels;
    const currentChannelIds = currentChannels.map((channel, index) => {
      return channel.id
    })
    let newChannels = currentChannels
    channels.forEach((channel, index) => {
      if (!currentChannelIds.includes(channel.id)) {
        newChannels.push(channel)
      }
    });
    if (currentChannels.length === newChannels.length && this.state.channelPaginationNum > 3) {
      return
    }
    this.setState({
      chatChannels: newChannels,
      fetchingPaginatedChannels: false,
      channelPaginationNum: this.state.channelPaginationNum + 1
    })
  }

  setupChannel = channelId => {
    if (!this.state.messages[channelId] || this.state.messages[channelId].length === 0 ||
      this.state.messages[channelId][0].reception_method === 'pushed'){
      getAllMessages(channelId, this.receiveAllMessages);
    }
    this.subscribePusher(`presence-channel-${channelId}`)
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
    })
  }

  receiveAllMessages = res => {
    const { chatChannelId, messages } = res;
    const newMessages = { ...this.state.messages, [chatChannelId]: messages };
    this.setState({ messages: newMessages, scrolled: false });
  };

  receiveNewMessage = message => {
    const receivedChatChannelId = message.chat_channel_id;
    if (!this.state.messages[receivedChatChannelId]) {
      return
    }
    const newMessages = this.state.messages[receivedChatChannelId].slice();
    newMessages.push(message);
    if (newMessages.length > 150) {
      newMessages.shift();
    }
    const newShowAlert =
      this.state.activeChannelId === receivedChatChannelId
        ? { showAlert: this.state.scrolled }
        : {};
    let newMessageChannelIndex = 0
    let newMessageChannel = null;
    let newChannelsObj = this.state.chatChannels.map((channel, index) => {
      if (receivedChatChannelId === channel["id"]){
        channel["last_message_at"] = new Date();
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
      sendOpen(
        receivedChatChannelId,
        this.handleChannelOpenSuccess,
        null,
      );
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
    let incomingCalls = this.state.incomingVideoCallChannelIds;
    incomingCalls.push(callObj.channelId)
    this.setState({incomingVideoCallChannelIds: incomingCalls})
  }

  receiveVideoCallHangup = () => {
    this.setState({activeVideoChannelId: null})
  }

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
    if (this.state.fetchingPaginatedChannels || this.state.chatChannels.length < 30) {
      return
    }
    const target = e.target;
    if((target.scrollTop + target.offsetHeight + 1800) > target.scrollHeight) {
      this.setState({fetchingPaginatedChannels: true})
      
      const filters = this.state.channelTypeFilter === 'all' ? {} : {filters: 'channel_type:'+this.state.channelTypeFilter};
      getChannels(
        this.state.filterQuery,
        this.state.activeChannelId,
        this.props,
        this.state.channelPaginationNum,
        filters,
        this.loadPaginatedChannels);
    }
  }

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
    // should check if user has the priviledge
    if (message.startsWith('/code')) {
      let newActiveContent = this.state.activeContent
      newActiveContent[this.state.activeChannelId] = {type_of: "code_editor"}
      this.setState({activeContent: newActiveContent})
    } else if (message.startsWith('/call')) {
      if (this.state.activeChannel.channel_type === 'direct') {
        this.setState({activeVideoChannelId: this.state.activeChannelId})
        window.pusher.channel(`presence-channel-${this.state.activeChannelId}`).trigger('client-initiatevideocall', {
          channelId: this.state.activeChannelId
        });
      } else {
        alert("Calls are only currently available in direct channels");
      }
    } else if (message.startsWith('/github')) {
      const args = message.split('/github ')[1].trim()
      let newActiveContent = this.state.activeContent
      newActiveContent[this.state.activeChannelId] = {type_of: "github", args: args }
      this.setState({activeContent: newActiveContent})
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
    let target = e.target;
    if (!target.dataset.channelId) {
      target = target.parentElement
    }
    this.triggerSwitchChannel(target.dataset.channelId, target.dataset.channelSlug);
  };

  answerVideoCall = () => {
    this.setState({
      activeVideoChannelId: this.state.activeChannelId,
      incomingVideoCallChannelIds: []
    })
  }

  hangupVideoCall = () => {
    window.pusher.channel(`presence-channel-${this.state.activeVideoChannelId}`).trigger('client-endvideocall', {});
    this.setState({
      activeVideoChannelId: null,
    })
  }

  triggerSwitchChannel = (id, slug) => {
    this.setState({
      activeChannel: this.filterForActiveChannel(this.state.chatChannels, id),
      activeChannelId: parseInt(id),
      scrolled: false,
      showAlert: false,
    });
    this.setupChannel(id);
    window.history.replaceState(null, null, "/connect/"+slug);
    if (!this.state.isMobileDevice) {
      document.getElementById("messageform").focus();
    }
    if (window.ga && ga.create) {
      ga('send', 'pageview', location.pathname + location.search);
    }
    sendOpen(
      id,
      this.handleChannelOpenSuccess,
      null,
    );
  }

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
    Notification.requestPermission(function (permission) {
      if (permission === "granted") {
        context.setState({notificationsPermission: "granted"});
        setupNotifications();
      }
    });
  }

  triggerActiveContent = e => {
    const target = e.target
    let newActiveContent = this.state.activeContent
    if (e.target.dataset.content && e.target.dataset.content != "exit") {
      e.preventDefault();
      newActiveContent[this.state.activeChannelId] = {type_of: "loading-user"}
      getContent('/api/'+target.dataset.content, this.setActiveContent, null)
    } else if (target.tagName.toLowerCase() === 'a' && target.href.startsWith('https://dev.to/')) {
      e.preventDefault();
      newActiveContent[this.state.activeChannelId] = {type_of: "loading-post"}
      getContent(`/api/articles/by_path?url=${target.href.split('https://dev.to')[1]}`, this.setActiveContent, null)
    } else if (target.dataset.content === "exit") {
      e.preventDefault();
      newActiveContent[this.state.activeChannelId] = null
    }
      this.setState({activeContent: newActiveContent})
  }

  setActiveContent = response => {
    let newActiveContent = this.state.activeContent
    newActiveContent[this.state.activeChannelId] = response
    this.setState({activeContent: newActiveContent});
    setTimeout(function() {
      document.getElementById("chat_activecontent").scrollTop = 0;
    }, 10);
  }

  handleChannelOpenSuccess = response => {
    const newChannelsObj = this.state.chatChannels.map(channel => {
      if (parseInt(response.channel) === channel["id"]){
        channel["last_opened_at"] = new Date();
      }
      return channel;
    });
    this.setState({ chatChannels: newChannelsObj });
  };

  triggerChannelTypeFilter = e => {
    const type = e.target.dataset.channelType;
    this.setState({channelTypeFilter: type})
    const filters = type === 'all' ? {} : {filters: 'channel_type:'+type};
    console.log(filters)
    getChannels(this.state.filterQuery, null, this.props, 0, filters, this.loadChannels);
  }

  handleFailure = err => {
    console.error(err);
  };

  renderMessages = () => {
    const { activeChannelId, messages, showTimestamp, activeChannel } = this.state;
    if (!messages[activeChannelId]) {
      return
    }
    if (messages[activeChannelId].length === 0 && activeChannel ) {
      const channelUsername = activeChannel.slug.replace(`${window.currentUser.username}/`, '').replace(`/${window.currentUser.username}`, '')
      return <div className="chatmessage" style={{color: "grey"}}>
        <div className="chatmessage__body">
          You and <a href={"/"+channelUsername} style={{color:activeChannel.channel_users[channelUsername].darker_color}} >@{channelUsername}</a> are connected because follow each other. All interactions <em><b>must</b></em> abide by the <a href="/code-of-conduct">code of conduct</a>.
        </div>
      </div>
    }
    return messages[activeChannelId].map(message => (
      <Message
        user={message.username}
        userID={message.user_id}
        profileImageUrl={message.profile_image_url}
        message={message.message}
        messageColor={message.messageColor}
        timestamp={showTimestamp ? message.timestamp : null}
        color={message.color}
        type={message.type}
        onContentTrigger={this.triggerActiveContent}
      />
    ));
  };

  triggerChannelFilter = e => {
      const filters = this.state.channelTypeFilter === 'all' ? {} : {filters: 'channel_type:'+this.state.channelTypeFilter};
      getChannels(e.target.value, null, this.props, 0, filters, this.loadChannels);
  }

  toggleExpand = () => {
    this.setState({expanded: !this.state.expanded})
  }

  renderChatChannels = () => {
    if (this.state.showChannelsList) {
      const notificationsPermission = this.state.notificationsPermission;
      let notificationsButton = "";
      let notificationsState = "";
      if (notificationsPermission === "waiting-permission") {
        notificationsButton = <div><button className="chat__notificationsbutton " onClick={this.triggerNotificationRequest}>Turn on Notifications</button></div>;
      } else if (notificationsPermission === "granted") {
        notificationsState = <div className="chat_chatconfig chat_chatconfig--on">Notificatins On</div>
      } else if (notificationsPermission === "denied") {
        notificationsState = <div className="chat_chatconfig chat_chatconfig--off">Notificatins Off</div>
      }
      if (this.state.expanded) {
        return (
          <div className="chat__channels chat__channels--expanded">
            {notificationsButton}
            <button className="chat__channelstogglebutt" onClick={this.toggleExpand}>{"<"}</button>
            <input placeholder='Filter' onKeyUp={this.triggerChannelFilter} />
            <div className='chat__channeltypefilter'>
              <button data-channel-type='all' onClick={this.triggerChannelTypeFilter} className={`chat__channeltypefilterbutton chat__channeltypefilterbutton--${this.state.channelTypeFilter === 'all' ? 'active' : 'inactive'}`}>
                all
              </button>
              <button data-channel-type='direct' onClick={this.triggerChannelTypeFilter} className={`chat__channeltypefilterbutton chat__channeltypefilterbutton--${this.state.channelTypeFilter === 'direct' ? 'active' : 'inactive'}`}>
                direct
              </button>
              <button data-channel-type='invite_only' onClick={this.triggerChannelTypeFilter} className={`chat__channeltypefilterbutton chat__channeltypefilterbutton--${this.state.channelTypeFilter === 'invite_only' ? 'active' : 'inactive'}`}>
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
              incomingVideoCallChannelIds={this.state.incomingVideoCallChannelIds}
            />
            {notificationsState}
          </div>
        )
      } else {
        return (
          <div className="chat__channels">
            {notificationsButton}
            <button
              class="chat__channelstogglebutt"
              onClick={this.toggleExpand}
              style={{width: "100%"}}
              >{">"}</button>
            <Channels
              incomingVideoCallChannelIds={this.state.incomingVideoCallChannelIds}
              activeChannelId={this.state.activeChannelId}
              chatChannels={this.state.chatChannels}
              handleSwitchChannel={this.handleSwitchChannel}
              expanded={this.state.expanded}
            />
            {notificationsState}
          </div>
        )
      }
    }
    return '';
  };

  renderActiveChatChannel = (channelHeader,incomingCall) => (
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
        resource={this.state.activeContent[this.state.activeChannelId]}
        onExit={this.triggerActiveContent}
        activeChannelId={this.state.activeChannelId}
        pusherKey={this.props.pusherKey}
        githubToken={this.props.githubToken}
        />
    </div>
  );

  

  render() {
    let channelHeader = <div className="activechatchannel__header">&nbsp;</div>
    let channelHeaderInner = ''
    const currentChannel = this.state.activeChannel
    if (currentChannel) {
      let channelHeaderInner = ''
      if (currentChannel.channel_type === "direct") {
        const username = currentChannel.slug.replace(`${window.currentUser.username}/`, '').replace(`/${window.currentUser.username}`, '');
        channelHeaderInner = <a href={'/'+username}>@{username}</a>
      }
      else {
        channelHeaderInner = currentChannel.channel_name;
      }
      channelHeader = <div className="activechatchannel__header">
                        {channelHeaderInner}
                      </div>
    }
    let vid = ''
    let incomingCall = ''
    if (this.state.activeVideoChannelId) {
      vid = <Video activeChannelId={this.state.activeChannelId} onExit={this.hangupVideoCall} />
    } else if (this.state.incomingVideoCallChannelIds.includes(this.state.activeChannelId) ) {
      incomingCall = <div className="activechatchannel__incomingcall" onClick={this.answerVideoCall}>👋 Incoming Video Call </div>
    }
    return (
      <div className={"chat chat--" + (this.state.expanded ? "expanded" : "contracted")}>
        {this.renderChatChannels()}
        <div className="chat__activechat">
          {vid}
          {this.renderActiveChatChannel(channelHeader, incomingCall)}
        </div>
      </div>
    );
  }
}
