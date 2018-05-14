import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { conductModeration, getAllMessages, sendMessage } from './actions';
import { hideMessages, scrollToBottom, setupObserver } from './util';
import Alert from './alert';
import Channels from './channels';
import Compose from './compose';
import Message from './message';
import setupPusher from './pusher';

class Chat extends Component {
  constructor(props) {
    super(props);
    this.handleFailure = this.handleFailure.bind(this);
    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.handleMessageSubmit = this.handleMessageSubmit.bind(this);
    this.handleSubmitOnClick = this.handleSubmitOnClick.bind(this);
    this.handleSuccess = this.handleSuccess.bind(this);
    this.observerCallback = this.observerCallback.bind(this);
    this.receiveAllMessages = this.receiveAllMessages.bind(this);
    this.receiveNewMessage = this.receiveNewMessage.bind(this);
    this.clearChannel = this.clearChannel.bind(this);
    this.redactUserMessages = this.redactUserMessages.bind(this);
    this.handleSwitchChannel = this.handleSwitchChannel.bind(this);
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
      activeChannelId: chatChannels[0].id,
      showChannelsList: chatOptions.showChannelsList,
    };
  }

  componentDidMount() {
    this.state.chatChannels.forEach(channel => {
      this.setupChannel(channel.id);
    });
    setupObserver(this.observerCallback);
  }

  componentDidUpdate() {
    if (!this.state.scrolled) {
      scrollToBottom();
    }
  }

  setupChannel(channelId) {
    getAllMessages(channelId, this.receiveAllMessages);
    setupPusher(this.props.pusherKey, {
      channelId,
      messageCreated: this.receiveNewMessage,
      channelCleared: this.clearChannel,
      redactUserMessages: this.redactUserMessages,
    });
  }

  observerCallback(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.setState({ scrolled: false, showAlert: false });
      } else {
        this.setState({ scrolled: true });
      }
    });
  }

  receiveAllMessages(res) {
    const { chatChannelId, messages } = res;
    const newMessages = { ...this.state.messages, [chatChannelId]: messages };
    this.setState({ messages: newMessages });
  }

  receiveNewMessage(message) {
    const receivedChatChannelId = message.chat_channel_id;
    const newMessages = this.state.messages[receivedChatChannelId].slice();
    newMessages.push(message);
    if (newMessages.length > 150) {
      newMessages.shift();
    }
    const newShowAlert =
      this.state.activeChannelId === receivedChatChannelId
        ? { showAlert: this.state.scrolled }
        : {};
    this.setState({
      ...newShowAlert,
      messages: {
        ...this.state.messages,
        [receivedChatChannelId]: newMessages,
      },
    });
  }

  redactUserMessages(res) {
    // This is shallow clone. This might cause a problem
    const clonedMessages = Object.assign({}, this.state.messages);
    const newMessages = hideMessages(clonedMessages, res.userId);
    this.setState({ messages: newMessages });
  }

  clearChannel(res) {
    const newMessages = { ...this.state.messages, [res.chat_channel_id]: [] };
    this.setState({ messages: newMessages });
  }

  handleKeyDown(e) {
    if (e.keyCode === 13) {
      e.preventDefault();
      if (e.target.value.length > 0) {
        this.handleMessageSubmit(e.target.value);
        e.target.value = '';
      }
    }
  }

  handleMessageSubmit(message) {
    // should check if user has the priviledge
    if (message[0] === '/') {
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
  }

  handleSwitchChannel(e) {
    e.preventDefault();
    this.setState({
      activeChannelId: e.target.dataset.channelId,
      scrolled: false,
      showAlert: false,
    });
  }

  handleSubmitOnClick(e) {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      this.handleMessageSubmit(message);
      document.getElementById('messageform').value = '';
    }
  }

  handleSuccess(response) {
    if (response.status === 'error') {
      this.receiveNewMessage(response.message);
    }
  }

  handleFailure(err) {
    console.error(err);
  }

  renderMessage() {
    const { activeChannelId, messages } = this.state;
    return messages[activeChannelId].map(message => (
      <Message
        user={message.username}
        message={message.message}
        timeStamp={message.timestamp}
        color={message.color}
        type={message.type}
      />
    ));
  }

  renderChatChannels() {
    if (this.state.showChannelsList) {
      return (
        <div className="chat__channels">
          <Channels
            activeChannelId={this.state.activeChannelId}
            chatChannels={this.state.chatChannels}
            handleSwitchChannel={this.handleSwitchChannel}
          />
        </div>
      );
    }
    return '';
  }

  renderActiveChatChannel() {
    return (
      <div className="activechatchannel">
        <div className="activechatchannel__messages" id="messagelist">
          {this.renderMessage()}
          <div id="messagelist__sentinel" />
        </div>
        <div className="activechatchannel__alerts">
          <Alert showAlert={this.state.showAlert} />
        </div>
        <div className="activechatchannel__form">
          <Compose
            handleKeyDown={this.handleKeyDown}
            handleSubmitOnClick={this.handleSubmitOnClick}
          />
        </div>
      </div>
    );
  }

  render() {
    return (
      <div className="chat">
        {this.renderChatChannels()}
        <div className="chat__activechat">{this.renderActiveChatChannel()}</div>
      </div>
    );
  }
}

Chat.propTypes = {
  pusherKey: PropTypes.number.isRequired,
  chatChannels: PropTypes.array.isRequired,
  chatOptions: PropTypes.object.isRequired,
};

export default Chat;
