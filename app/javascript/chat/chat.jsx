import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { conductModeration, getAllMessages, sendMessage } from './actions';
import { hideMessages, scrollToBottom, setupObserver } from './util';
import Alert from './alert';
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
    this.state = {
      messages: [],
      scrolled: false,
      showAlert: false,
    };
  }

  componentDidMount() {
    getAllMessages(this.receiveAllMessages);
    setupPusher(this.props.pusherKey, {
      messageCreated: this.receiveNewMessage,
      channelCleared: this.clearChannel,
      redactUserMessages: this.redactUserMessages,
    });
    setupObserver(this.observerCallback);
  }

  componentDidUpdate() {
    if (!this.state.scrolled) {
      scrollToBottom();
    }
  }

  observerCallback(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        this.setState({ scrolled: false, showAlert: false });
      } else {
        this.setState({ scrolled: true });
      }
    });
  }

  receiveAllMessages(res) {
    this.setState({ messages: res.messages });
  }

  receiveNewMessage(message) {
    const newMessages = this.state.messages.slice();
    newMessages.push(message);
    if (newMessages.length > 150) {
      newMessages.shift();
    }
    this.setState({
      messages: newMessages,
      showAlert: this.state.scrolled,
    });
  }

  redactUserMessages(res) {
    const newMessages = hideMessages(this.state.messages.slice(), res.userId);
    this.setState({ messages: newMessages });
  }

  clearChannel() {
    this.setState({ messages: [] });
  }

  handleKeyDown(e) {
    if (e.keyCode === 13) {
      e.preventDefault();
      this.handleMessageSubmit(e.target.value);
      e.target.value = '';
    }
  }

  handleMessageSubmit(message) {
    // should check if user has the priviledge
    if (message[0] === '/') {
      conductModeration(message, this.handleSuccess, this.handleFailure);
    } else {
      sendMessage(message, this.handleSuccess, this.handleFailure);
    }
  }

  handleSubmitOnClick(e) {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    this.handleMessageSubmit(message);
    document.getElementById('messageform').value = '';
  }

  handleSuccess(response) {
    if (Object.prototype.hasOwnProperty.call(response, 'error')) {
      console.log(response.error);
    }
  }

  handleFailure(err) {
    console.error(err);
  }

  renderMessage() {
    return this.state.messages.map(message => (
      <Message
        user={message.username}
        message={message.message}
        timeStamp={message.timestamp}
        color={message.color}
        hidden={message.hidden}
      />
    ));
  }

  render() {
    return (
      <div className="chatchannel">
        <div className="chatchannel__messages" id="messagelist">
          {this.renderMessage()}
          <div id="messagelist__sentinel" />
        </div>
        <div className="chatchannel__alerts">
          <Alert showAlert={this.state.showAlert} />
        </div>
        <div className="chatchannel__form">
          <Compose
            handleKeyDown={this.handleKeyDown}
            handleSubmitOnClick={this.handleSubmitOnClick}
          />
        </div>
      </div>
    );
  }
}

Chat.propTypes = {
  pusherKey: PropTypes.number.isRequired,
};

export default Chat;
