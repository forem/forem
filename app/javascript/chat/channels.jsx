import { h } from 'preact';
import PropTypes from 'prop-types';
import ConfigImage from 'images/three-dots.svg';

const Channels = ({ activeChannelId, chatChannels, handleSwitchChannel, expanded }) => {
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

    let content = ''

    if (expanded) {
      content = <span>
                  <span 
                    data-channel-slug={modififedSlug}
                    className={"chatchanneltabindicator chatchanneltabindicator--" + newMessagesIndicatorClass}
                    data-channel-id={channel.id}
                    data-channel-slug={modififedSlug}>
                    {indicatorPic}
                  </span>
                  {name}
                </span>
    } else {
      if (channel.channel_type === "direct") {

        content = <span 
                    data-channel-slug={modififedSlug}
                    className={"chatchanneltabindicator chatchanneltabindicator--" + newMessagesIndicatorClass}
                    data-channel-id={channel.id}
                    data-channel-slug={modififedSlug}>
                    {indicatorPic}
                  </span>
      } else {
        content = name
      }
    }

    return (
      <button
        key={channel.id}
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
          {content}
        </span>
      </button>
    );
  });
  let channelsListFooter = ""
  if (channels.length === 30) {
    channelsListFooter = <div className="chatchannels__channelslistfooter">You may connect devs you mutually follow. Use the filter to discover all your channels.</div>
  }
  return (
    <div className="chatchannels">
      <div className="chatchannels__channelslist">
        {channels}
        {channelsListFooter}
      </div>
      <div className="chatchannels__config">
        <img src={ConfigImage} style={{height: "18px"}}/>
        <div className="chatchannels__configmenu">
          <a href="/settings">DEV Settings</a>
          <a href="/report-abuse">Report Abuse</a>
        </div>
      </div>
    </div>
  );
};

Channels.propTypes = {
  activeChannelId: PropTypes.number.isRequired,
  chatChannels: PropTypes.array.isRequired,
  handleSwitchChannel: PropTypes.func.isRequired,
  expanded: PropTypes.bool.isRequired,
};

export default Channels;
