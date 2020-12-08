import { h } from 'preact';
import PropTypes from 'prop-types';
// eslint-disable-next-line import/no-unresolved
import ConfigImage from 'images/overflow-horizontal.svg';
import ChannelButton from './components/ChannelButton';
import { channelSorter } from './util';

const Channels = ({
  activeChannelId,
  chatChannels,
  unopenedChannelIds,
  handleSwitchChannel,
  expanded,
  filterQuery = '',
  channelsLoaded,
  currentUserId,
  triggerActiveContent,
}) => {
  const sortedChatChannels = channelSorter(
    chatChannels,
    currentUserId,
    filterQuery,
  );
  const discoverableChannels = sortedChatChannels.discoverableChannels.map(
    (channel) => {
      return (
        <ChannelButton
          channel={channel}
          discoverableChannel
          triggerActiveContent={triggerActiveContent}
          isActiveChannel={
            parseInt(activeChannelId, 10) === channel.chat_channel_id
          }
        />
      );
    },
  );
  const channels = sortedChatChannels.activeChannels.map((channel) => {
    const isActive = parseInt(activeChannelId, 10) === channel.chat_channel_id;
    const isUnopened =
      !isActive && unopenedChannelIds.includes(channel.chat_channel_id);
    const newMessagesIndicator = isUnopened ? 'new' : 'old';
    const otherClassname = isActive
      ? 'chatchanneltab--active'
      : 'chatchanneltab--inactive';

    return (
      <ChannelButton
        channel={channel}
        newMessagesIndicator={newMessagesIndicator}
        otherClassname={otherClassname}
        handleSwitchChannel={handleSwitchChannel}
        isUnopened={isUnopened}
      />
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
      <div className="chatchannels__channelslistheader" role="alert">
        <span role="img" aria-label="emoji">
          👋
        </span>{' '}
        Welcome to
        <b> Connect</b>! You may message anyone you mutually follow.
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
    // TODO: The <div /> below should be converted into a real menu or <nav />
    configFooter = (
      <div className="chatchannels__config">
        <img alt="configration" src={ConfigImage} style={{ height: '18px' }} />
        <div className="chatchannels__configmenu" role="menu">
          <a href="/settings" role="menuitem">
            Settings
          </a>
          <a href="/report-abuse" role="menuitem">
            Report Abuse
          </a>
        </div>
      </div>
    );
  }
  return (
    <div className="chatchannels">
      <div
        className="chatchannels__channelslist"
        id="chatchannels__channelslist"
        data-testid="chat-channels-list"
      >
        {topNotice}
        {channels}
        {discoverableChannels.length > 0 && filterQuery.length > 0 ? (
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
