import { h } from 'preact';
import PropTypes from 'prop-types';

import { InviteForm } from './InviteForm';
import { SettingsForm } from './SettingsForm';

export const ModSection = ({
  handleChannelInvitations,
  invitationUsernames,
  handleInvitationUsernames,
  channelDescription,
  handleDescriptionChange,
  channelDiscoverable,
  handleChannelDiscoverableStatus,
  handleChannelDescriptionChanges,
  currentMembershipRole,
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
};
