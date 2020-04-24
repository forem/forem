import { h } from 'preact';
import PropTypes from 'prop-types';
// eslint-disable-next-line import/no-unresolved
import ConfigImage from 'images/three-dots.svg';

const Channels = ({
  activeChannelId,
  chatChannels,
  unopenedChannelIds,
  handleSwitchChannel,
  expanded,
  filterQuery,
  channelsLoaded,
  currentUserId,
  triggerActiveContent,
}) => {
  const discoverableChannels = chatChannels
    .filter((channel) => channel.viewable_by !== currentUserId)
    .map((channel) => {
      return (
        <button
          type="button"
          key={channel.id}
          className="chatchanneltabbutton"
          onClick={triggerActiveContent}
          data-content="sidecar-channel-request"
          data-channel-id={channel.chat_channel_id}
          data-channel-name={channel.channel_name}
        >
          <span
            className="chatchanneltab chatchanneltab--inactive"
            data-channel-id={channel.chat_channel_id}
            data-channel-name={channel.channel_name}
            data-channel-slug={channel.channel_modified_slug}
            style={{
              border: `1px solid ${channel.channel_color}`,
              boxShadow: `3px 3px 0px ${channel.channel_color}`,
            }}
          >
            <span
              data-channel-slug={channel.channel_modified_slug}
              className="chatchanneltabindicator"
              data-channel-name={channel.channel_name}
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
            {channel.channel_name}
          </span>
        </button>
      );
    });
  console.log(chatChannels);
  const channels = chatChannels
    .filter(
      (channel) =>
        channel.viewable_by === currentUserId &&
        channel.status !== 'joining_request',
    )
    .map((channel) => {
      const isActive =
        parseInt(activeChannelId, 10) === channel.chat_channel_id;
      const isUnopened =
        !isActive && unopenedChannelIds.includes(channel.chat_channel_id);
      const newMessagesIndicator = isUnopened ? 'new' : 'old';
      const otherClassname = isActive
        ? 'chatchanneltab--active'
        : 'chatchanneltab--inactive';

      return (
        <button
          type="button"
          key={channel.id}
          className="chatchanneltabbutton"
          onClick={handleSwitchChannel}
          data-channel-id={channel.chat_channel_id}
          data-channel-slug={channel.channel_modified_slug}
        >
          <span
            className={`chatchanneltab ${otherClassname} chatchanneltab--${newMessagesIndicator}`}
            data-channel-id={channel.chat_channel_id}
            data-channel-slug={channel.channel_modified_slug}
            style={{
              border: `1px solid ${channel.channel_color}`,
              boxShadow: `3px 3px 0px ${channel.channel_color}`,
            }}
          >
            <span
              data-channel-slug={channel.channel_modified_slug}
              className={`chatchanneltabindicator chatchanneltabindicator--${newMessagesIndicator}`}
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
    });

  let topNotice = '';
  if (
    expanded &&
    filterQuery.length === 0 &&
    channelsLoaded &&
    (channels.length === 0 || channels[0].messages_count === 0)
  ) {
    topNotice = (
      <div className="chatchannels__channelslistheader">
        <span role="img" aria-label="emoji">
          👋
        </span>
        {' '}
        Welcome to
        <b> DEV Connect</b>
        ! You may message anyone you mutually follow.
      </div>
    );
  }
  let channelsListFooter = '';
  if (channels.length === 30) {
    channelsListFooter = (
      <div className="chatchannels__channelslistfooter">...</div>
    );
  }
  let configFooter = '';
  if (expanded) {
    configFooter = (
      <div className="chatchannels__config">
        <img alt="" src={ConfigImage} style={{ height: '18px' }} />
        <div className="chatchannels__configmenu">
          <a href="/settings">DEV Settings</a>
          <a href="/report-abuse">Report Abuse</a>
        </div>
      </div>
    );
  }
  return (
    <div className="chatchannels">
      <div
        className="chatchannels__channelslist"
        id="chatchannels__channelslist"
      >
        {topNotice}
        {channels}
        {discoverableChannels.length > 0 ? (
          <div>
            <span className="crayons-indicator crayons-indicator--">
              Global Channel Search
            </span>
            {discoverableChannels}
          </div>
        ) : (
          ''
        )}
        {channelsListFooter}
      </div>
      {configFooter}
    </div>
  );
};

Channels.propTypes = {
  activeChannelId: PropTypes.number.isRequired,
  chatChannels: PropTypes.arrayOf(PropTypes.objectOf()).isRequired,
  unopenedChannelIds: PropTypes.arrayOf().isRequired,
  handleSwitchChannel: PropTypes.func.isRequired,
  triggerActiveContent: PropTypes.func.isRequired,
  expanded: PropTypes.bool.isRequired,
  filterQuery: PropTypes.string.isRequired,
  channelsLoaded: PropTypes.bool.isRequired,
  currentUserId: PropTypes.string.isRequired,
};

export default Channels;
