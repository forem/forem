import { h, createRef } from 'preact';
import { useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { defaultChannelPropTypes } from '../../common-prop-types/channel-list-prop-type';
import { ChannelImage } from './ChannelImage';
import { Button } from '@crayons';

/**
 * Render a button to switch focus to a channel
 *
 * @param {object} props
 *
 * @component
 *
 * @example
 *
 * <ChannelButton
 *   channel={channel}
     newMessagesIndicator={newMessagesIndicator}
     otherClassname={otherClassname}
     handleSwitchChannel={handleSwitchChannel}
     isUnopened={isUnopened}
 * />
 *
 */

export function ChannelButton(props) {
  const buttonRef = createRef();
  const { isActiveChannel = false } = props;

  useEffect(() => {
    if (isActiveChannel) {
      buttonRef.current.click();
    }
  }, [isActiveChannel, buttonRef]);

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
      <ChannelImage
        channel={channel}
        newMessagesIndicator={newMessagesIndicator}
        discoverableChannel={discoverableChannel}
      />
      {isUnopened ? (
        <span className="crayons-indicator crayons-indicator--accent crayons-indicator--bullet" />
      ) : null}
      {channel.channel_name}
    </Button>
  );
}

ChannelButton.propTypes = {
  channel: defaultChannelPropTypes,
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
