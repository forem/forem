import { h } from 'preact';
import PropTypes from 'prop-types';

import InviteForm from './InviteForm';
import SettingsForm from './SettingsForm';

const ModSection = ({
  handleChatChannelInvitations,
  invitationUsernames,
  handleInvitationUsernames,
  channelDescription,
  handleDescriptionChange,
  channelDiscoverable,
  handleChannelDiscoverableStatus,
  handleChannelDescriptionChanges,
}) => {
  return (
    <div className="mod-section">
      <InviteForm
        handleInvitationUsernames={handleInvitationUsernames}
        invitationUsernames={invitationUsernames}
        handleChatChannelInvitations={handleChatChannelInvitations}
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
  handleChatChannelInvitations: PropTypes.func.isRequired,
  invitationUsernames: PropTypes.func.isRequired,
  channelDescription: PropTypes.string.isRequired,
  handleDescriptionChange: PropTypes.func.isRequired,
  handleChannelDiscoverableStatus: PropTypes.func.isRequired,
  handleChannelDescriptionChanges: PropTypes.func.isRequired,
  channelDiscoverable: PropTypes.bool.isRequired,
};

export default ModSection;
