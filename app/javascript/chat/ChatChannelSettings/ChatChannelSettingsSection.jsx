import { h } from 'preact';
import PropTypes from 'prop-types';

import ModSection from './ModSection';
import PersonalSettings from './PersonalSetting';
import LeaveMembershipSection from './LeaveMembershipSection';
import ModFaqSection from './ModFaqSection';
import ChannelDescriptionSection from './ChannelDescriptionSection';
import ChatChannelMembershipSection from './ChatChannelMembershipSection';

const ChatChannelSettingsSection = ({
  channelDiscoverable,
  updateCurrentMembershipNotificationSettings,
  handleleaveChatChannelMembership,
  handlePersonChatChennelSetting,
  handleChannelDescriptionChanges,
  handleChannelDiscoverableStatus,
  handleDescriptionChange,
  handleChatChannelInvitations,
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
      handleChatChannelInvitations={handleChatChannelInvitations}
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
      handlePersonChatChennelSetting={handlePersonChatChennelSetting}
      className="channel-personal-seeting"
    />
    <LeaveMembershipSection
      currentMembershipRole={currentMembership.role}
      handleleaveChatChannelMembership={handleleaveChatChannelMembership}
      className="channel-leave-membership-section"
    />
    <ModFaqSection
      currentMembershipRole={currentMembership.role}
      email="yo@dev.to"
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
  handleleaveChatChannelMembership: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  removeMembership: PropTypes.func.isRequired,
  toggleScreens: PropTypes.func.isRequired,
  handleInvitationUsernames: PropTypes.func.isRequired,
  handleChatChannelInvitations: PropTypes.func.isRequired,
  handleDescriptionChange: PropTypes.func.isRequired,
  handleChannelDiscoverableStatus: PropTypes.func.isRequired,
  handleChannelDescriptionChanges: PropTypes.func.isRequired,
  handlePersonChatChennelSetting: PropTypes.func.isRequired,
  updateCurrentMembershipNotificationSettings: PropTypes.func.isRequired,
};

export default ChatChannelSettingsSection;
