import { h } from 'preact';
import PropTypes from 'prop-types';

import { defaulMembershipPropType } from '../../common-prop-types/membership-prop-type';
import Membership from './Membership';
import { Button } from '@crayons';

const ActiveMembershipSection = ({
  activeMemberships,
  removeMembership,
  currentMembershipRole,
  toggleScreens,
}) => {
  const activeMembershipList = activeMemberships.slice(0, 4);

  return (
    <div
      data-testid="active-memberships"
      className="p-4 grid gap-2 crayons-card mb-4"
      data-active-count={activeMemberships ? activeMemberships.length : 0}
    >
      <h3 className="mb-2 active_members">Members</h3>
      {activeMembershipList.map((activeMembership) => (
        <Membership
          membership={activeMembership}
          removeMembership={removeMembership}
          membershipType="active"
          currentMembershipRole={currentMembershipRole}
          className="active-member"
        />
      ))}
      <div className="row align-center">
        <Button
          className="align-center view-all-memberships"
          size="s"
          onClick={toggleScreens}
          type="button"
        >
          View All
        </Button>
      </div>
    </div>
  );
};

ActiveMembershipSection.propTypes = {
  activeMemberships: PropTypes.arrayOf(defaulMembershipPropType).isRequired,
  removeMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.string.isRequired,
  toggleScreens: PropTypes.func.isRequired,
};

export default ActiveMembershipSection;
