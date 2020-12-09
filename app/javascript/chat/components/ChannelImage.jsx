import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChannelPropTypes } from '../../common-prop-types/channel-list-prop-type';

export default function ChannelImage(props) {
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

ChannelImage.propTypes = {
  channel: defaultChannelPropTypes,
  discoverableChannel: PropTypes.bool,
  newMessagesIndicator: PropTypes.string,
};
