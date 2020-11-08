import { h } from 'preact';
import PropTypes from 'prop-types';

import InviteForm from './InviteForm';
import SettingsForm from './SettingsForm';

/**
 *
 * This component render the mod section
 *
 *
 * @param {object} props
 * @param {function} props.handleChannelInvitations
 * @param {string} props.invitationUsernames
 * @param {function} props.handleInvitationUsernames
 * @param {string} props.channelDescription
 * @param {function} props.handleDescriptionChange
 * @param {object} props.channelDiscoverable
 * @param {object} props.handleChannelDiscoverableStatus
 * @param {object} props.handleChannelDescriptionChanges
 * @param {object} props.currentMembershipRole
 *
 * @component
 *
 * @example
 *
 * <ModSection
 *  handleChannelInvitations={handleChannelInvitations}
 *  invitationUsernames={invitationUsernames}
 *  handleInvitationUsernames={handleInvitationUsernames}
 *  channelDescription={channelDescription}
 *  handleDescriptionChange={handleDescriptionChange}
 *  channelDiscoverable={channelDiscoverable}
 *  handleChannelDiscoverableStatus={handleChannelDiscoverableStatus}
 *  handleChannelDescriptionChanges={handleChannelDescriptionChanges}
 *  currentMembershipRole={currentMembershipRole}
 * />
 */
export default function ModSection({
  handleChannelInvitations,
  invitationUsernames,
  handleInvitationUsernames,
  channelDescription,
  handleDescriptionChange,
  channelDiscoverable,
  handleChannelDiscoverableStatus,
  handleChannelDescriptionChanges,
  currentMembershipRole,
}) {
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
}

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
