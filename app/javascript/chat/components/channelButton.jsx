import { h } from 'preact';
import PropTypes from 'prop-types';

const ChannelButton = ({
  channel,
  handleSwitchChannel,
  otherClassname,
  newMessagesIndicator,
  isUnopened,
  discoverableChannel,
  triggerActiveContent,
}) => {
  return (
    <button
      type="button"
      key={channel.id}
      className="chatchanneltabbutton"
      onClick={discoverableChannel ? triggerActiveContent : handleSwitchChannel}
      data-content="sidecar-channel-request"
      data-channel-id={channel.chat_channel_id}
      data-channel-slug={channel.channel_modified_slug}
      data-channel-status={channel.status}
      data-channel-name={channel.channel_name}
    >
      <span
        className={
          discoverableChannel
            ? 'chatchanneltab chatchanneltab--inactive'
            : `chatchanneltab ${otherClassname} chatchanneltab--${newMessagesIndicator}`
        }
        data-channel-id={channel.chat_channel_id}
        data-content="sidecar-channel-request"
        data-channel-slug={channel.channel_modified_slug}
        data-channel-status={channel.status}
        data-channel-name={channel.channel_name}
        style={{
          border: `1px solid ${channel.channel_color}`,
          boxShadow: `3px 3px 0px ${channel.channel_color}`,
        }}
      >
        <span
          data-channel-slug={channel.channel_modified_slug}
          className={
            discoverableChannel
              ? 'chatchanneltabindicator'
              : `chatchanneltabindicator chatchanneltabindicator--${newMessagesIndicator}`
          }
          data-channel-id={channel.chat_channel_id}
        >
          <img
            src={channel.channel_image}
            alt="pic"
            className={
              channel.channel_type === 'direct'
                ? 'chatchanneltabindicatordirectimage'
                : 'chatchanneltabindicatordirectimage invert-channel-image'
            }
          />
        </span>
        {isUnopened ? (
          <span className="crayons-indicator crayons-indicator--accent crayons-indicator--bullet" />
        ) : (
          ''
        )}
        {channel.channel_name}
      </span>
    </button>
  );
};

ChannelButton.propTypes = {
  channel: PropTypes.shape({
    channel_name: PropTypes.string,
    channel_color: PropTypes.string,
    channel_type: PropTypes.string,
    channel_modified_slug: PropTypes.string,
    id: PropTypes.number,
    chat_channel_id: PropTypes.number,
    status: PropTypes.string,
    channel_image: PropTypes.string,
  }).isRequired,
  discoverableChannel: PropTypes.bool,
  handleSwitchChannel: PropTypes.func,
  triggerActiveContent: PropTypes.func,
  newMessagesIndicator: PropTypes.string,
  otherClassname: PropTypes.string,
  isUnopened: PropTypes.string,
};

ChannelButton.defaultProps = {
  otherClassname: '',
  isUnopened: '',
  newMessagesIndicator: '',
  discoverableChannel: false,
  handleSwitchChannel: null,
  triggerActiveContent: null,
};
export default ChannelButton;
