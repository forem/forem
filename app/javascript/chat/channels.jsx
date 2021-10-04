import { h } from 'preact';
import PropTypes from 'prop-types';
import { Trans } from 'react-i18next';
import { i18next } from '../i18n/l10n';
import { ChannelButton } from './components/ChannelButton';
import { ConfigMenu } from './configMenu';
import { channelSorter } from './util';

export const Channels = ({
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
          key={channel.chat_channel_id}
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
        key={channel.chat_channel_id}
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
      // eslint-disable-next-line react/no-danger
      <div
        className="chatchannels__channelslistheader"
        role="alert">
          <Trans i18nKey="chat.welcome"
            // eslint-disable-next-line react/jsx-key
            components={[<span role="img" aria-label="emoji" />]} />
      </div>
    );
  }

  let channelsListFooter = '';
  if (channels.length === 30) {
    channelsListFooter = (
      <div className="chatchannels__channelslistfooter">
        {i18next.t('common.etc')}
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
              {i18next.t('chat.search')}
            </span>
            {discoverableChannels}
          </div>
        ) : (
          ''
        )}
        {channelsListFooter}
      </div>

      <ConfigMenu />
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
