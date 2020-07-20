import { h } from 'preact';
import PropTypes from 'prop-types';

import InviteForm from './InviteForm';
import SettingsForm from './SettingsForm';

const ModSection = ({
  handleChannelInvitations,
  invitationUsernames,
  handleInvitationUsernames,
  channelDescription,
  handleDescriptionChange,
  channelDiscoverable,
  handleChannelDiscoverableStatus,
  handleChannelDescriptionChanges,
  currentMembershipRole,
  isPrivateOrgChannel
}) => {
  if (currentMembershipRole === 'member') {
    return null;
  }

  return (
    <div className="mod-section">
      <InviteForm
        handleInvitationUsernames={handleInvitationUsernames}
        invitationUsernames={invitationUsernames}
        handleChannelInvitations={handleChannelInvitations}
      />
      <SettingsForm
        channelDescription={channelDescription}
        handleDescriptionChange={handleDescriptionChange}
        channelDiscoverable={channelDiscoverable}
        handleChannelDiscoverableStatus={handleChannelDiscoverableStatus}
        handleChannelDescriptionChanges={handleChannelDescriptionChanges}
        isPrivateOrgChannel={isPrivateOrgChannel}
      />
    </div>
  );
};

ModSection.propTypes = {
  handleInvitationUsernames: PropTypes.func.isRequired,
  handleChannelInvitations: PropTypes.func.isRequired,
  invitationUsernames: PropTypes.func.isRequired,
  channelDescription: PropTypes.string.isRequired,
  handleDescriptionChange: PropTypes.func.isRequired,
  handleChannelDiscoverableStatus: PropTypes.func.isRequired,
  handleChannelDescriptionChanges: PropTypes.func.isRequired,
  channelDiscoverable: PropTypes.bool.isRequired,
  isPrivateOrgChannel: PropTypes.bool.isRequired,
};

export default ModSection;
