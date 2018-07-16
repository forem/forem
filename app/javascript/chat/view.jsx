

import { h, Component } from 'preact';

export default class View extends Component {

  render() {
    const channels = this.props.channels.map((channel) => {
      return <div className='chatNonChatView_contentblock'>
                <h2>{channel.channel_name}</h2>
                <div><em>{channel.description}</em></div>
                <button className='cta' onClick={this.props.onAcceptInvitation} data-content={channel.membership_id}>Accept</button>
                <button className='cta' onClick={this.props.onDeclineInvitation} data-content={channel.membership_id}>Decline</button>
              </div>
    });
    return  <div className="chatNonChatView">
              <div className="container">
                <button
                  class="chatNonChatView_exitbutton"
                  data-content="exit"
                  onClick={this.props.onViewExit}
                  >×</button>
                <h1>Channel Invitations 🤗</h1>
                {channels}
              </div>
            </div>
  }

}