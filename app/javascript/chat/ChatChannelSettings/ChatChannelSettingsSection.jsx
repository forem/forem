import { h } from 'preact';
import PropTypes from 'prop-types';

import { ModSection } from './ModSection';
import { PersonalSettings } from './PersonalSetting';
import { LeaveMembershipSection } from './LeaveMembershipSection';
import { ModFaqSection } from './ModFaqSection';
import { ChannelDescriptionSection } from './ChannelDescriptionSection';
import { ChatChannelMembershipSection } from './ChatChannelMembershipSection';

export const ChatChannelSettingsSection = ({
  channelDiscoverable,
  updateCurrentMembershipNotificationSettings,
  handleleaveChannelMembership,
  handlePersonChannelSetting,
  handleChannelDescriptionChanges,
  handleChannelDiscoverableStatus,
  handleDescriptionChange,
  handleChannelInvitations,
  handleInvitationUsernames,
  toggleScreens,
  removeMembership,
  chatChannelAcceptMembership,
  channelDescription,
  chatChannel,
  currentMembership,
  activeMemberships,
  pendingMemberships,
  requestedMemberships,
  invitationUsernames,
  showGlobalBadgeNotification,
}) => (
  <div>
    <ChannelDescriptionSection
      channelName={chatChannel.name}
      channelDescription={chatChannel.description}
      currentMembershipRole={currentMembership.role}
      className="channel-description-section"
    />
    <ChatChannelMembershipSection
      currentMembershipRole={currentMembership.role}
      activeMemberships={activeMemberships}
      removeMembership={removeMembership}
      pendingMemberships={pendingMemberships}
      requestedMemberships={requestedMemberships}
      chatChannelAcceptMembership={chatChannelAcceptMembership}
      toggleScreens={toggleScreens}
      className="channel-membership-sections"
    />
    <ModSection
      invitationUsernames={invitationUsernames}
      handleInvitationUsernames={handleInvitationUsernames}
      handleChannelInvitations={handleChannelInvitations}
      channelDescription={channelDescription}
      handleDescriptionChange={handleDescriptionChange}
      channelDiscoverable={channelDiscoverable}
      handleChannelDiscoverableStatus={handleChannelDiscoverableStatus}
      handleChannelDescriptionChanges={handleChannelDescriptionChanges}
      currentMembershipRole={currentMembership.role}
      className="channel-mod-section"
    />
    <PersonalSettings
      updateCurrentMembershipNotificationSettings={
        updateCurrentMembershipNotificationSettings
      }
      showGlobalBadgeNotification={showGlobalBadgeNotification}
      handlePersonChannelSetting={handlePersonChannelSetting}
      className="channel-personal-seeting"
    />
    <LeaveMembershipSection
      currentMembershipRole={currentMembership.role}
      handleleaveChannelMembership={handleleaveChannelMembership}
      className="channel-leave-membership-section"
    />
    <ModFaqSection
      currentMembershipRole={currentMembership.role}
      className="channel-mod-faq"
    />
  </div>
);

ChatChannelSettingsSection.propTypes = {
  chatChannel: PropTypes.isRequired,
  currentMembership: PropTypes.isRequired,
  activeMemberships: PropTypes.isRequired,
  pendingMemberships: PropTypes.isRequired,
  requestedMemberships: PropTypes.isRequired,
  invitationUsernames: PropTypes.string.isRequired,
  channelDescription: PropTypes.string.isRequired,
  channelDiscoverable: PropTypes.bool.isRequired,
  showGlobalBadgeNotification: PropTypes.bool.isRequired,
  handleleaveChannelMembership: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  removeMembership: PropTypes.func.isRequired,
  toggleScreens: PropTypes.func.isRequired,
  handleInvitationUsernames: PropTypes.func.isRequired,
  handleChannelInvitations: PropTypes.func.isRequired,
  handleDescriptionChange: PropTypes.func.isRequired,
  handleChannelDiscoverableStatus: PropTypes.func.isRequired,
  handleChannelDescriptionChanges: PropTypes.func.isRequired,
  handlePersonChannelSetting: PropTypes.func.isRequired,
  updateCurrentMembershipNotificationSettings: PropTypes.func.isRequired,
};
