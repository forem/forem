import { h } from 'preact';
import PropTypes from 'prop-types';
import Membership from './Membership';

/**
 * This component render all the List of Active chat channel memberships
 * 
 * @param {object} props
 *  
 * @param {object} membership
 * @param {object} currentMembership
 * @param {function} removeMembership
 * @param {function} handleUpdateMembershipRole
 * @param {boolean} membershipCount
 * 
 * @component
 * 
 * @example
 * 
 *<Membership
    membership={pendingMembership}
    removeMembership={removeMembership}
    currentMembershipRole={currentMembershipRole}
    handleUpdateMembershipRole={handleUpdateMembershipRole}
    membershipCount={membershipCount}
  />
 * 
 */
export default function MembershipSection({
  memberships,
  currentMembership,
  removeMembership,
  handleUpdateMembershipRole,
  membershipCount,
}) {
  if (!memberships || memberships.length === 0) {
    return <p className="lh-base">No membership</p>;
  }

  return (
    <div className="membership-section">
      {memberships.map((activeMembership) => (
        <Membership
          membership={activeMembership}
          membershipType="active"
          currentMembershipRole={() => {}}
          className="active-member"
          currentMembership={currentMembership}
          removeMembership={removeMembership}
          handleUpdateMembershipRole={handleUpdateMembershipRole}
          showActionButton={membershipCount > 1}
        />
      ))}
    </div>
  );
}

MembershipSection.propType = {
  memberships: PropTypes.arrayOf(
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
  currentMembership: PropTypes.isRequired,
  removeMembership: PropTypes.func.isRequired,
  handleUpdateMembershipRole: PropTypes.func.isRequired,
  membershipCount: PropTypes.number.isRequired,
};
