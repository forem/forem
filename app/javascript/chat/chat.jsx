import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { conductModeration, getAllMessages, sendMessage, sendOpen, getAdditionalChannels, getContent } from './actions';
import { hideMessages, scrollToBottom, setupObserver, setupNotifications, getNotificationState } from './util';
import Alert from './alert';
import Channels from './channels';
import Compose from './compose';
import Message from './message';
import Content from './content';
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
      messages: chatChannels.reduce(
        (accumulator, target) => ({ ...accumulator, [target.id]: [] }),
        {},
      ),
      scrolled: false,
      showAlert: false,
      chatChannels,
      activeChannelId: chatOptions.activeChannelId,
      showChannelsList: chatOptions.showChannelsList,
      showTimestamp: chatOptions.showTimestamp,
      notificationsPermission: null,
      activeContent: null
    };
  }

  componentDidMount() {
    this.state.chatChannels.forEach((channel, index) => {
      if ( index < 6 ) {
        this.setupChannel(channel.id);
      }
      if (channel.channel_type === "open") {
        setupPusher(this.props.pusherKey, {
          channelId: `open-channel-${channel.id}`,
          messageCreated: this.receiveNewMessage,
          channelCleared: this.clearChannel,
          redactUserMessages: this.redactUserMessages,
          liveCoding: null
        });
      } else {
        setupPusher(this.props.pusherKey, {
          channelId: `presence-channel-${channel.id}`,
          messageCreated: this.receiveNewMessage,
          channelCleared: this.clearChannel,
          redactUserMessages: this.redactUserMessages,
          liveCoding: this.liveCoding
        });
      }
    });
    setupObserver(this.observerCallback);
    setupPusher(this.props.pusherKey, {
      channelId: `private-message-notifications-${window.currentUser.id}`,
      messageCreated: this.receiveNewMessage,
      channelCleared: this.clearChannel,
      redactUserMessages: this.redactUserMessages,
    });
    sendOpen(
      this.state.activeChannelId,
      this.handleChannelOpenSuccess,
      null,
    );
    this.setState({notificationsPermission: getNotificationState()});
    if (this.state.showChannelsList) {
      getAdditionalChannels(this.loadAdditionalChannels);
    }
    document.getElementById("messageform").focus();
  }

  componentDidUpdate() {
    if (!this.state.scrolled) {
      scrollToBottom();
    }
  }

  liveCoding = e => {
    if (this.state.activeContent === {type_of: "code_editor"}) {
      return 
    }
    this.setState({activeContent: {type_of: "code_editor"}})
  }

  loadAdditionalChannels = channels => {
    this.setState({chatChannels: channels});
    this.setupChannel(this.state.activeChannelId);
  }

  setupChannel = channelId => {
    if (!this.state.messages[channelId] || this.state.messages[channelId].length === 0 ||
      this.state.messages[channelId][0].reception_method === 'pushed'){
      getAllMessages(channelId, this.receiveAllMessages);
    }
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

  receiveAllMessages = res => {
    const { chatChannelId, messages } = res;
    const newMessages = { ...this.state.messages, [chatChannelId]: messages };
    this.setState({ messages: newMessages });
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
    const newChannelsObj = this.state.chatChannels.map(channel => {
      if (receivedChatChannelId === channel["id"]){
        channel["last_message_at"] = new Date();
      }
      return channel;
    });
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
      this.setState({activeContent: {type_of: "code_editor"}})
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
    this.setupChannel(e.target.dataset.channelId);
    this.setState({
      activeChannelId: parseInt(e.target.dataset.channelId),
      scrolled: false,
      showAlert: false,
      activeContent: null
    });
    window.history.replaceState(null, null, "/connect/"+e.target.dataset.channelSlug);
    document.getElementById("messageform").focus();
    if (window.ga && ga.create) {
      ga('send', 'pageview', location.pathname + location.search);
    }
    sendOpen(
      e.target.dataset.channelId,
      this.handleChannelOpenSuccess,
      null,
    );
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
    Notification.requestPermission(function (permission) {
      if (permission === "granted") {
        context.setState({notificationsPermission: "granted"});
        setupNotifications();
      }
    });
  }

  triggerActiveContent = e => {
    const target = e.target
    if (e.target.dataset.content && e.target.dataset.content != "exit") {
      e.preventDefault();
      this.setState({activeContent: {type_of: "loading-user"}})
      getContent('/api/'+target.dataset.content, this.setActiveContent, null)
    }
    else if (target.tagName.toLowerCase() === 'a' && target.href.startsWith('https://dev.to/')) {
      e.preventDefault();
      this.setState({activeContent: {type_of: "loading-post"}})
      getContent(`/api/articles/by_path?url=${target.href.split('https://dev.to')[1]}`, this.setActiveContent, null)
    } else if (target.dataset.content === "exit") {
      e.preventDefault();
      this.setState({activeContent: null})
    }
  }

  setActiveContent = response => {
    this.setState({activeContent: response});
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

  handleFailure = err => {
    console.error(err);
  };

  renderMessages = () => {
    const { activeChannelId, messages, showTimestamp } = this.state;
    if (!messages[activeChannelId]) {
      return
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

  renderChatChannels = () => {
    if (this.state.showChannelsList) {
      const notificationsPermission = this.state.notificationsPermission;
      let notificationsButton = "";
      let notificationsState = "";
      if (notificationsPermission === "waiting-permission") {
        notificationsButton = <div><button class="chat__notificationsbutton " onClick={this.triggerNotificationRequest}>Turn on Notifications</button></div>;
      } else if (notificationsPermission === "granted") {
        notificationsState = <div class="chat_chatconfig chat_chatconfig--on">Notificatins On</div>
      } else if (notificationsPermission === "denied") {
        notificationsState = <div class="chat_chatconfig chat_chatconfig--off">Notificatins Off</div>
      }
      return (
        <div className="chat__channels">
          {notificationsButton}
          <Channels
            activeChannelId={this.state.activeChannelId}
            chatChannels={this.state.chatChannels}
            handleSwitchChannel={this.handleSwitchChannel}
          />
          {notificationsState}
        </div>
      );
    }
    return '';
  };

  renderActiveChatChannel = () => (
    <div className="activechatchannel">
      <div className="activechatchannel__conversation">
        <div className="activechatchannel__messages" id="messagelist">
          {this.renderMessages()}
          <div className="messagelist__sentinel" id="messagelist__sentinel" />
        </div>
        <div className="activechatchannel__alerts">
          <Alert showAlert={this.state.showAlert} />
        </div>
        <div className="activechatchannel__form">
          <Compose
            handleSubmitOnClick={this.handleSubmitOnClick}
            handleKeyDown={this.handleKeyDown}
          />
        </div>
      </div>
      <Content
        resource={this.state.activeContent}
        onExit={this.triggerActiveContent}
        activeChannelId={this.state.activeChannelId}
        pusherKey={this.props.pusherKey}
        />
    </div>
  );

  

  render() {
    return (
      <div className="chat">
        {this.renderChatChannels()}
        <div className="chat__activechat">
          {this.renderActiveChatChannel()}
        </div>
      </div>
    );
  }
}
