import { h } from 'preact';
import PropTypes from 'prop-types';

import ActiveMembershipSection from './ActiveMembershipsSection';
import PendingMembershipSection from './PendingMembershipSection'
import RequestedMembershipSection from './RequestedMembershipSection';

const ChatChannelMembershipSection = ({
  pendingMemberships,
  requestedMemberships,
  removePendingMembership,
  removeRequestedMembership,
  chatChannelAcceptMembership,
  activeMemberships,
  removeActiveMembership,
  currentMembershipRole
}) => {
  return (
    <div className="membership-list">
      <ActiveMembershipSection
        activeMemberships={activeMemberships}
        removeActiveMembership={removeActiveMembership}
        currentMembershipRole={currentMembershipRole}
      />
      <PendingMembershipSection
        pendingMemberships={pendingMemberships}
        removePendingMembership={removePendingMembership}
        currentMembershipRole={currentMembershipRole}
      />
      <RequestedMembershipSection
        requestedMemberships={requestedMemberships}
        removeRequestedMembership={removeRequestedMembership}
        chatChannelAcceptMembership={chatChannelAcceptMembership}
        currentMembershipRole={currentMembershipRole}
      />
    </div>
  )
}

ChatChannelMembershipSection.propTypes = {
  pendingMemberships: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string.isRequired,
    membership_id: PropTypes.number.isRequired,
    user_id: PropTypes.number.isRequired,
    role: PropTypes.string.isRequired,
    image: PropTypes.string.isRequired,
    username: PropTypes.string.isRequired,
  })).isRequired,
  requestedMemberships: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string.isRequired,
    membership_id: PropTypes.number.isRequired,
    user_id: PropTypes.number.isRequired,
    role: PropTypes.string.isRequired,
    image: PropTypes.string.isRequired,
    username: PropTypes.string.isRequired,
  })).isRequired,
  activeMemberships: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string.isRequired,
    membership_id: PropTypes.number.isRequired,
    user_id: PropTypes.number.isRequired,
    role: PropTypes.string.isRequired,
    image: PropTypes.string.isRequired,
    username: PropTypes.string.isRequired,
    status: PropTypes.string.isRequired,
  })).isRequired,
  removeActiveMembership: PropTypes.func.isRequired,
  removeRequestedMembership: PropTypes.func.isRequired,
  removePendingMembership: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.string.isRequired
}

export default ChatChannelMembershipSection;
