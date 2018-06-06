import { h, render, Component } from 'preact';

class UnopenedChannelNotice extends Component {
  constructor(props) {
    super(props);
    this.state = { visible: true }
    this.handleClick = this.handleClick.bind(this);
  }

  handleClick() {
    this.setState({visible: false})
  }
  render() {
    if (this.state.visible) {
      const channels = this.props.channels.map(channel => {
        return <a
          href={"/chat/"+channel.adjusted_slug}
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
  if (location.pathname.startsWith("/chat")) {
    return
  }
  fetch('/chat_channels?state=unopened', {
    method: 'GET',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(json => {
      if (json.length > 0) {
        render(<UnopenedChannelNotice channels={json} />, document.getElementById('message-notice'));
      } else {
        render(null, document.getElementById('message-notice'));
      }
    })
    .catch(error => {
      console.log(error);
    });
}
