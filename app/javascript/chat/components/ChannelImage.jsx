import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChannelPropTypes } from '../../common-prop-types/channel-list-prop-type';

/**
 * Returns an image to help users identify chat channels
 *
 * @param {object} channel - Contains information about the channel this image represents
 * @param {string} newMessagesIndicator - Used to construct a CSS classname
 * @param {boolean} discoverableChannel - Used to determine which CSS class should be applied
 *
 * @example
 * <ChannelImage
     channel={{channel_name: "Example Channel",
               channel_type: "direct",
               channel_modified_slug: "someslug-f7ff2c5a6a",
               id: 1,
               chat_channel_id: 20,
               status: "active",
               channel_image: "/some/path/to/image"}}
     newMessagesIndicator="old"
     discoverableChannel={false}
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
