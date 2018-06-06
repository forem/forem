import { h } from 'preact';
import PropTypes from 'prop-types';

const Channels = ({ activeChannelId, chatChannels, handleSwitchChannel }) => {
  const channels = chatChannels.map(channel => {
    const otherClassname =
      parseInt(activeChannelId, 10) === channel.id
        ? 'chatchanneltab--active'
        : 'chatchanneltab--inactive';
    const name = channel.channel_type === "direct" ? '@'+channel.slug.replace(`${window.currentUser.username}/`, '').replace(`/${window.currentUser.username}`, '') : channel.channel_name
    const newMessagesIndicatorClass = new Date(channel.last_opened_at) < new Date(channel.last_message_at) ? "chatchanneltabindicator--new" : "chatchanneltabindicator--old"
    const modififedSlug = channel.channel_type === "direct" ? name : channel.slug;
    return (
      <button
        className='chatchanneltabbutton'
        onClick={handleSwitchChannel}
        data-channel-id={channel.id}
        data-channel-slug={modififedSlug}
      >
        <span className={`chatchanneltab ${otherClassname}`}
          data-channel-id={channel.id}
          data-channel-slug={modififedSlug}
        >
          <span 
            data-channel-slug={modififedSlug}
            className={"chatchanneltabindicator " + newMessagesIndicatorClass}
          ></span> {name} 
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
