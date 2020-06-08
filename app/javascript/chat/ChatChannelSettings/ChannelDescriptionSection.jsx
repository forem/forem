import { h } from 'preact';
import PropTypes from 'prop-types';

const ChannelDescriptionSection = ({
  channelName,
  channelDescription,
  currentMembershipRole
}) => {
  return (
    <div className="p-4 grid gap-2 crayons-card mb-4 channel_details">
      <h1 className="mb-1">{channelName}</h1>
      <p>{channelDescription}</p>
      <p className="fw-bold">
        You are a channel 
        {' '}
        {currentMembershipRole}
      </p>
    </div>
  )
}

ChannelDescriptionSection.propTypes = {
    channelName: PropTypes.func.isRequired,
    currentMembershipRole: PropTypes.func.isRequired,
    channelDescription: PropTypes.func.isRequired
}

export default ChannelDescriptionSection;
