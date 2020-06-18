import { h } from 'preact';
import PropTypes from 'prop-types';
import Membership from './Membership';

const PendingMembershipSection = ({
  pendingMemberships,
  removeMembership,
  currentMembershipRole,
}) => {
  if (currentMembershipRole !== 'mod') {
    return null;
  }

  return (
    <div className="p-4 grid gap-2 crayons-card mb-4 pending_memberships">
      <h3 className="mb-2">Pending Invitations</h3>
      {pendingMemberships && pendingMemberships.length > 0
        ? pendingMemberships.map((pendingMembership) => (
          <Membership
            membership={pendingMembership}
            removeMembership={removeMembership}
            membershipType="pending"
            currentMembershipRole={currentMembershipRole}
            className="pending-member"
          />
          ))
        : null}
    </div>
  );
};

PendingMembershipSection.propTypes = {
  pendingMemberships: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
      membership_id: PropTypes.number.isRequired,
      user_id: PropTypes.number.isRequired,
      role: PropTypes.string.isRequired,
      image: PropTypes.string.isRequired,
      username: PropTypes.string.isRequired,
      status: PropTypes.string.isRequired,
    }),
  ).isRequired,
  removeMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.func.isRequired,
};

export default PendingMembershipSection;
