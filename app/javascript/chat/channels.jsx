import { h } from 'preact';
import PropTypes from 'prop-types';

const Channels = ({ activeChannelId, chatChannels, handleSwitchChannel }) => {
  const channels = chatChannels.map(channel => {
    const isActive = parseInt(activeChannelId, 10) === channel.id
    const lastOpened = channel.last_opened_at ? channel.last_opened_at : channel.channel_users[window.currentUser.username].last_opened_at
    const isUnopened = new Date(channel.last_message_at) > new Date(lastOpened);
    
    const otherClassname =
      isActive
        ? 'chatchanneltab--active'
        : 'chatchanneltab--inactive';
    const name = channel.channel_type === "direct" ? '@'+channel.slug.replace(`${window.currentUser.username}/`, '').replace(`/${window.currentUser.username}`, '') : channel.channel_name
    const newMessagesIndicatorClass = isUnopened ? "new" : "old"
    const modififedSlug = channel.channel_type === "direct" ? name : channel.slug;
    const indicatorPic = channel.channel_type === "direct" ? <img src = {channel.channel_users[name.replace('@','')].profile_image} /> : ''
    let channelColor = 'transparent'
    if (channel.channel_type === "direct" && isActive) {
      channelColor = channel.channel_users[name.replace('@','')].darker_color;
    } else if ( isActive ) {
      channelColor = '#4e57ef'
    }
    return (
      <button
        className='chatchanneltabbutton'
        onClick={handleSwitchChannel}
        data-channel-id={channel.id}
        data-channel-slug={modififedSlug}
      >
        <span className={`chatchanneltab ${otherClassname} chatchanneltab--${newMessagesIndicatorClass}`}
          data-channel-id={channel.id}
          data-channel-slug={modififedSlug}
          style={{border:`1px solid ${channelColor}`, boxShadow: `3px 3px 0px ${channelColor}`}}
        >
          <span 
            data-channel-slug={modififedSlug}
            className={"chatchanneltabindicator chatchanneltabindicator--" + newMessagesIndicatorClass}
          >
          {indicatorPic}
          </span> {name} 
        </span>
      </button>
    );
  });

  return (
    <div className="chatchannels">
      <div className="chatchannels__channelslist">{channels}</div>
    </div>
  );
};

Channels.propTypes = {
  activeChannelId: PropTypes.number.isRequired,
  chatChannels: PropTypes.array.isRequired,
  handleSwitchChannel: PropTypes.func.isRequired,
};

export default Channels;
