import { h } from 'preact';
import PropTypes from 'prop-types';

import InviteForm from './InviateForm';
import SettingsFrom from './SettingsForm';

const ModSection = ({
  handleChatChannelInvitations,
  invitationUsernames,
  handleInvitationUsernames,
  channelDescription,
  handleDescriptionChange,
  channelDiscoverable,
  handleChannelDiscoverableStatus,
  handleChannelDescriptionChanges,
  currentMembershipRole,
}) => {
  if (currentMembershipRole !== 'mod') {
    return null;
  }

  return (
    <div className="mod-section">
      <InviteForm
        handleInvitationUsernames={handleInvitationUsernames}
        invitationUsernames={invitationUsernames}
        handleChatChannelInvitations={handleChatChannelInvitations}
      />
      <SettingsFrom
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
  handleChatChannelInvitations: PropTypes.func.isRequired,
  invitationUsernames: PropTypes.func.isRequired,
  channelDescription: PropTypes.string.isRequired,
  handleDescriptionChange: PropTypes.func.isRequired,
  handleChannelDiscoverableStatus: PropTypes.func.isRequired,
  handleChannelDescriptionChanges: PropTypes.func.isRequired,
  channelDiscoverable: PropTypes.bool.isRequired,
  currentMembershipRole: PropTypes.string.isRequired,
};

export default ModSection;
