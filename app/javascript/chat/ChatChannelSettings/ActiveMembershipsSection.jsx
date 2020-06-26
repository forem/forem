import { h } from 'preact';
import PropTypes from 'prop-types';
import Membership from './Membership';

const ActiveMembershipSection = ({
  activeMemberships,
  removeMembership,
  currentMembershipRole,
  toggelScreens,
}) => {
  const RenderActiveMembershipManager = () => {
    toggelScreens();
  };

  const activeMembershipList = activeMemberships.slice(0, 4);

  return (
    <div
      data-testid="active-memberships"
      className="p-4 grid gap-2 crayons-card mb-4"
      data-active-count={activeMemberships ? activeMemberships.length : 0}
    >
      <h3 className="mb-2 active_members">Members</h3>
      {activeMembershipList && activeMembershipList.length > 0
        ? activeMembershipList.map((activeMembership) => (
          <Membership
            membership={activeMembership}
            removeMembership={removeMembership}
            membershipType="active"
            currentMembershipRole={currentMembershipRole}
            className="active-member"
          />
          ))
        : null}
      <div className="row view-membership-btn">
        <button
          className="crayons-btn align-center crayons-btn--s view-all-memberships"
          onClick={() => RenderActiveMembershipManager()}
          type="button"
        >
          View All
        </button>
      </div>
    </div>
  );
};

ActiveMembershipSection.propTypes = {
  activeMemberships: PropTypes.arrayOf(
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
  currentMembershipRole: PropTypes.string.isRequired,
  toggelScreens: PropTypes.func.isRequired,
};

export default ActiveMembershipSection;
