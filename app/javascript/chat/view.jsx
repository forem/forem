import { h, Component } from 'preact';

export default class View extends Component {
  channel = (props) => {
    return (
      <div className="chatNonChatView_contentblock">
        <h2>{props.channel.channel_name}</h2>
        <div>
          <em>{props.channel.description}</em>
        </div>
        <button
          className="cta"
          onClick={this.props.onAcceptInvitation}
          data-content={props.channel.membership_id}
        >
          Accept
        </button>
        <button
          className="cta"
          onClick={this.props.onDeclineInvitation}
          data-content={props.channel.membership_id}
        >
          Decline
        </button>
      </div>
    );
  };

  render() {
    const channels = this.props.channels.map(channel => {
      return <this.channel channel={channel} />
    });
    return (
      <div className="chatNonChatView">
        <div className="container">
          <button
            className="chatNonChatView_exitbutton"
            data-content="exit"
            onClick={this.props.onViewExit}
          >
            ×
          </button>
          <h1>Channel Invitations 🤗</h1>
          {channels}
        </div>
      </div>
    );
  }
}
