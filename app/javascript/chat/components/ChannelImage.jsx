import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChannelPropTypes } from '../../common-prop-types/channel-list-prop-type';

/**
 * Returns an image to help users identify chat channels
 *
 * @param {object} channel - Contains information about the channel this image represents
 * @param {string} newMessagesIndicator
 * @param {boolean} discoverableChannel
 *
 * @example
 * <ChannelImage
     channel={channel}
     newMessagesIndicator={newMessagesIndicator}
     discoverableChannel={discoverableChannel}
   />
 */

export function ChannelImage({
  channel,
  newMessagesIndicator,
  discoverableChannel,
}) {
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
  newMessagesIndicator: PropTypes.string,
  discoverableChannel: PropTypes.bool,
};
