import { h, createRef } from 'preact';
import { useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

export default function ChannelButton(props) {
  const buttonRef = createRef();
  const { isActiveChannel = false } = props;

  useEffect(() => {
    if (isActiveChannel) {
      buttonRef.current.click();
    }
  }, [isActiveChannel, buttonRef]);

  function renderChannelImage() {
    const { channel, newMessagesIndicator, discoverableChannel } = props;

    return (
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
          data-channel-id={channel.chat_channel_id}
          className={
            channel.channel_type === 'direct'
              ? 'chatchanneltabindicatordirectimage'
              : 'chatchanneltabindicatordirectimage invert-channel-image'
          }
        />
      </span>
    );
  }

  const {
    channel,
    handleSwitchChannel,
    otherClassname,
    newMessagesIndicator,
    isUnopened,
    discoverableChannel,
    triggerActiveContent,
  } = props;

  return (
    <Button
      ref={buttonRef}
      key={channel.id}
      className={
        discoverableChannel
          ? 'chatchanneltab chatchanneltab--inactive crayons-btn--ghost'
          : `chatchanneltab ${otherClassname} chatchanneltab--${newMessagesIndicator} crayons-btn--ghost`
      }
      onClick={discoverableChannel ? triggerActiveContent : handleSwitchChannel}
      data-content="sidecar-channel-request"
      data-channel-id={channel.chat_channel_id}
      data-channel-slug={channel.channel_modified_slug}
      data-channel-status={channel.status}
      data-channel-name={channel.channel_name}
    >
      {renderChannelImage()}
      {isUnopened ? (
        <span className="crayons-indicator crayons-indicator--accent crayons-indicator--bullet" />
      ) : null}
      {channel.channel_name}
    </Button>
  );
}

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
