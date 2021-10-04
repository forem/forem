import { h } from 'preact';
import PropTypes from 'prop-types';

import { defaultMembershipPropType } from '../../common-prop-types/membership-prop-type';
import { Membership } from './Membership';
import { i18next } from '@utilities/locale';

export const PendingMembershipSection = ({
  pendingMemberships,
  removeMembership,
  currentMembershipRole,
}) => {
  if (currentMembershipRole === 'member') {
    return null;
  }

  return (
    <div
      data-testid="pending-memberships"
      className="p-4 grid gap-2 crayons-card mb-4 pending_memberships"
      data-pending-count={pendingMemberships ? pendingMemberships.length : 0}
    >
      <h3 className="mb-2">{i18next.t('chat.settings.pending')}</h3>
      {pendingMemberships && pendingMemberships.length > 0
        ? pendingMemberships.map((pendingMembership) => (
            // eslint-disable-next-line react/jsx-key
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
  pendingMemberships: PropTypes.arrayOf(defaultMembershipPropType).isRequired,
  removeMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.func.isRequired,
};
