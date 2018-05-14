import { h } from 'preact';
import PropTypes from 'prop-types';

const Channels = ({ activeChannelId, chatChannels, handleSwitchChannel }) => {
  const channels = chatChannels.map(channel => {
    const otherClassname =
      parseInt(activeChannelId, 10) === channel.id
        ? 'chatchanneltab--active'
        : 'chatchanneltab--inactive';
    return (
      <button
        className={`chatchanneltab ${otherClassname}`}
        onClick={handleSwitchChannel}
        data-channel-id={channel.id}
      >
        {channel.channel_name}
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
