import { h, Component } from 'preact';
import PropTypes from 'prop-types';

/**
 * TODO: Instead of calling this function in render, use jsx (<SetupButton />).
 */
function SetupButton({ className, onClickCallback, dataContent, btnLabel }) {
  return (
    <button
      type="button"
      className={className}
      onClick={onClickCallback}
      data-content={dataContent}
    >
      {btnLabel}
    </button>
  );
}

SetupButton.propTypes = {
  className: PropTypes.string.isRequired,
  onClickCallback: PropTypes.func.isRequired,
  dataContent: PropTypes.string.isRequired,
  btnLabel: PropTypes.string.isRequired,
};

export default class View extends Component {
  static propTypes = {
    onAcceptInvitation: PropTypes.func.isRequired,
    onDeclineInvitation: PropTypes.func.isRequired,
    onViewExit: PropTypes.func.isRequired,
    channels: PropTypes.arrayOf(PropTypes.object).isRequired,
  };

  channel = props => {
    const { onAcceptInvitation, onDeclineInvitation } = this.props;
    return (
      <div className="chatNonChatView_contentblock">
        <h2>{props.channel.channel_name}</h2>
        <div>
          <em>{props.channel.description}</em>
        </div>
        {SetupButton({
          className: 'cta',
          onClickCallback: onAcceptInvitation,
          dataContent: props.channel.membership_id,
          btnLabel: 'Accept',
        })}
        {SetupButton({
          className: 'cta',
          onClickCallback: onDeclineInvitation,
          dataContent: props.channel.membership_id,
          btnLabel: 'Decline',
        })}
      </div>
    );
  };

  render() {
    const { onViewExit, channels: channelsFromProps } = this.props;
    const channels = channelsFromProps.map(channel => {
      return <this.channel channel={channel} />;
    });
    return (
      <div className="chatNonChatView">
        <div className="container">
          {SetupButton({
            className: 'chatNonChatView_exitbutton',
            onClickCallback: onViewExit,
            dataContent: 'exit',
            btnLabel: '×',
          })}
          <h1>
            Channel Invitations
            {' '}
            <span role="img" aria-label="hugging-emoji">
              🤗
            </span>
          </h1>
          {channels}
        </div>
      </div>
    );
  }
}
