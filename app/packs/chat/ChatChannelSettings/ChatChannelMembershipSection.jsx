import { h } from 'preact';
import PropTypes from 'prop-types';

import { defaultMembershipPropType } from '../../common-prop-types/membership-prop-type';
import { ActiveMembershipsSection } from './ActiveMembershipsSection';
import { PendingMembershipSection } from './PendingMembershipSection';
import { RequestedMembershipSection } from './RequestedMembershipSection';

export const ChatChannelMembershipSection = ({
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
      <ActiveMembershipsSection
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
  pendingMemberships: PropTypes.arrayOf(defaultMembershipPropType).isRequired,
  requestedMemberships: PropTypes.arrayOf(defaultMembershipPropType).isRequired,
  activeMemberships: PropTypes.arrayOf(defaultMembershipPropType).isRequired,
  removeMembership: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.string.isRequired,
  toggleScreens: PropTypes.func.isRequired,
};
