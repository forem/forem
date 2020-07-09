import { h } from 'preact';
import PropTypes from 'prop-types';

import ActiveMembershipSection from './ActiveMembershipsSection';
import PendingMembershipSection from './PendingMembershipSection'
import RequestedMembershipSection from './RequestedMembershipSection';

const ChatChannelMembershipSection = ({
  pendingMemberships,
  requestedMemberships,
  chatChannelAcceptMembership,
  activeMemberships,
  removeMembership,
  currentMembershipRole
}) => {
  return (
    <div className="membership-list">
      <ActiveMembershipSection
        activeMemberships={activeMemberships}
        removeMembership={removeMembership}
        currentMembershipRole={currentMembershipRole}
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
  removeMembership: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.string.isRequired
}

export default ChatChannelMembershipSection;
