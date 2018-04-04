import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { getAllMessages, sendMessage } from './actions';
import { scrollToBottom } from './util';
import Compose from './compose';
import Message from './message';
import setupPusher from './pusher';

class Chat extends Component {
  constructor(props) {
    super(props);
    this.receiveAllMessages = this.receiveAllMessages.bind(this);
    this.receiveNewMessage = this.receiveNewMessage.bind(this);
    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.handleMessageSubmit = this.handleMessageSubmit.bind(this);
    this.handleSubmitOnClick = this.handleSubmitOnClick.bind(this);
    this.handleFailure = this.handleFailure.bind(this);
    this.state = {
      messages: [],
    };
  }

  componentDidMount() {
    getAllMessages(this.receiveAllMessages);
    setupPusher(this.props.pusherKey, this.receiveNewMessage);
  }

  componentDidUpdate() {
    scrollToBottom();
  }

  receiveAllMessages(res) {
    this.setState({ messages: res.messages });
  }

  receiveNewMessage(message) {
    const newMessages = this.state.messages.slice();
    newMessages.push(message);
    this.setState({ messages: newMessages });
  }

  handleKeyDown(e) {
    if (e.keyCode === 13) {
      e.preventDefault();
      this.handleMessageSubmit(e.target.value);
      e.target.value = '';
    }
  }

  handleMessageSubmit(message) {
    sendMessage(message, null, this.handleFailure);
  }

  handleSubmitOnClick(e) {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    sendMessage(message, null, this.handleFailure);
    document.getElementById('messageform').value = '';
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
      />
    ));
  }

  render() {
    return (
      <div className="chatchannel">
        <div className="chatchannel__messages" id="messagelist">
          { this.renderMessage() }
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
