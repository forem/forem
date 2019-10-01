import { h, Component } from 'preact';

const setupButton = ({className = '', onClickCallback, dataContent = '', btnLabel = ''}) => {
  return (
    <button
      className={className}
      onClick={onClickCallback}
      data-content={dataContent}
    >
      {btnLabel}
    </button>
  )
}

export default class View extends Component {
  channel = (props) => {
    return (
      <div className="chatNonChatView_contentblock">
        <h2>{props.channel.channel_name}</h2>
        <div>
          <em>{props.channel.description}</em>
        </div>
        {
          setupButton({
            className: 'cta',
            onClickCallback: this.props.onAcceptInvitation,
            dataContent: props.channel.membership_id,
            btnLabel: 'Accept'
          })
        }
        {
          setupButton({
            className: 'cta',
            onClickCallback: this.props.onDeclineInvitation,
            dataContent: props.channel.membership_id,
            btnLabel: 'Decline'
          })
        }
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
          {
            setupButton({
              className: 'chatNonChatView_exitbutton',
              onClickCallback: this.props.onViewExit,
              dataContent: 'exit',
              btnLabel: '×'
            })
          }
          <h1>Channel Invitations 🤗</h1>
          {channels}
        </div>
      </div>
    );
  }
}
