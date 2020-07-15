import { h } from 'preact';
import PropTypes from 'prop-types';

import { defaulMembershipPropType } from '../../common-prop-types/membership-prop-type';
import ActiveMembershipSection from './ActiveMembershipsSection';
import PendingMembershipSection from './PendingMembershipSection';
import RequestedMembershipSection from './RequestedMembershipSection';

const ChatChannelMembershipSection = ({
  pendingMemberships,
  requestedMemberships,
  chatChannelAcceptMembership,
  activeMemberships,
  removeMembership,
  currentMembershipRole,
  toggleScreens,
}) => {
  return (
    <div className="membership-list">
      <ActiveMembershipSection
        activeMemberships={activeMemberships}
        removeMembership={removeMembership}
        currentMembershipRole={currentMembershipRole}
        toggleScreens={toggleScreens}
      />
      <PendingMembershipSection
        pendingMemberships={pendingMemberships}
        removeMembership={removeMembership}
        currentMembershipRole={currentMembershipRole}
      />
      <RequestedMembershipSection
        requestedMemberships={requestedMemberships}
        removeMembership={removeMembership}
        chatChannelAcceptMembership={chatChannelAcceptMembership}
        currentMembershipRole={currentMembershipRole}
      />
    </div>
  );
};

ChatChannelMembershipSection.propTypes = {
  pendingMemberships: PropTypes.arrayOf(defaulMembershipPropType).isRequired,
  requestedMemberships: PropTypes.arrayOf(defaulMembershipPropType).isRequired,
  activeMemberships: PropTypes.arrayOf(defaulMembershipPropType).isRequired,
  removeMembership: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.string.isRequired,
  toggleScreens: PropTypes.func.isRequired,
};

export default ChatChannelMembershipSection;
