import { h, render, Component } from 'preact';
import setupPusher from './pusher';



class UnopenedChannelNotice extends Component {
  constructor(props) {
    super(props);
    const unopenedChannels = this.props.unopenedChannels;
    const visible = unopenedChannels.length > 0 ? true : false;
    this.state = {
      visible: visible,
      unopenedChannels }
  }

  componentDidMount() {
    setupPusher(this.props.pusherKey, {
      channelId: `message-notifications-${window.currentUser.id}`,
      messageCreated: this.receiveNewMessage,
    });
  }

  receiveNewMessage = e => {
    let channels = this.state.unopenedChannels;
    const newObj = {adjusted_slug: e.chat_channel_adjusted_slug}
    if(channels.filter(obj => obj.adjusted_slug === newObj.adjusted_slug).length === 0 &&
      newObj.adjusted_slug != `@${window.currentUser.username}`) {
      channels.push(newObj);
    }
    this.setState({visible: channels.length > 0, unopenedChannels: channels})
  }

  handleClick = e => {
    this.setState({visible: false})
  }
  render() {
    if (this.state.visible) {
      const channels = this.state.unopenedChannels.map(channel => {
        return <a
          href={"/💌/"+channel.adjusted_slug}
          style={{
          background: "#66e2d5",
          color: "black",
          padding: "2px 7px",
          display: "inline-block",
          margin: "3px 6px",
          borderRadius: "3px"}}>{channel.adjusted_slug}</a>
      });
      return (
        <div
          onClick={this.handleClick}
          style={{
          position: 'fixed',
          zIndex: '200',
          top: '44px',
          right: 0,
          left: 0,
          background: '#333333',
          borderBottom: '1px solid black',
          color: 'white',
          fontWeight: 'bold',
          textAlign: 'center',
          fontSize: '15px',
          opacity: '0.94',
          padding: '12px 5px 3px'}}>
          <span style={{
            fontSize: "24px",
            verticalAlign: "-4px",
            display: "inline-block",
            marginRight: "3px"}}>💌</span> New Message from {channels}
          <span style={{ color: "#fefa87"}}>(beta testing)</span>
        </div>
      );
    }
  }
}

export default function getUnopenedChannels(user, successCb) {
  if (location.pathname.startsWith("/💌")) {
    return
  }
  fetch('/chat_channels?state=unopened', {
    method: 'GET',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(json => {
      render(<UnopenedChannelNotice unopenedChannels={json} pusherKey={document.body.dataset.pusherKey} />, document.getElementById('message-notice'));
    })
    .catch(error => {
      console.log(error);
    });
}
