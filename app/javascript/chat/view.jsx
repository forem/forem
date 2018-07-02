

import { h, Component } from 'preact';

export default class View extends Component {

  render() {
    const channels = this.props.channels.map((channel) => {
      return <div>{channel.channel_name} 
                <button onClick={this.props.onAcceptInvitation} data-content={channel.membership_id}>Accept</button>
                <button onClick={this.props.onDeclineInvitation} data-content={channel.membership_id}>Decline</button>
              </div>
    });
    return  <div className="chatNonChatView">
              <button
                class="chatNonChatView_exitbutton"
                data-content="exit"
                onClick={this.props.onViewExit}
                >×</button>
              <h1>Channel Invitations</h1>
              <h2>Invitations are a work in progress ❤️</h2>
              {channels}
            </div>
  }

}