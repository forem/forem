import { h } from 'preact';
import PropTypes from 'prop-types';
import { Membership } from './Membership';
import { i18next } from '@utilities/locale';

export const MembershipSection = ({
  memberships,
  currentMembership,
  removeMembership,
  handleUpdateMembershipRole,
  membershipCount,
}) => {
  if (!memberships || memberships.length === 0) {
    return <p className="lh-base">{i18next.t('chat.settings.no_member')}</p>;
  }

  return (
    <div className="membership-section">
      {memberships.map((activeMembership) => (
        // eslint-disable-next-line react/jsx-key
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
