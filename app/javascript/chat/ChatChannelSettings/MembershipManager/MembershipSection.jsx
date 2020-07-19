import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaulMembershipPropType } from '../../../common-prop-types/membership-prop-type';
import Membership from './Membership';

const MembershipSection = ({
  memberships,
  currentMembership,
  removeMembership,
  handleUpdateMembershipRole,
}) => {
  if (!memberships || memberships.length === 0) {
    return <p className="lh-base">No membership</p>;
  }

  const membershipCount = memberships.length;

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
};

MembershipSection.propType = {
  memberships: PropTypes.arrayOf(defaulMembershipPropType).isRequired,
  currentMembership: PropTypes.isRequired,
  removeMembership: PropTypes.func.isRequired,
  handleUpdateMembershipRole: PropTypes.func.isRequired,
};

export default MembershipSection;
