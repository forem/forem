import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultMembershipPropType } from '../../common-prop-types/membership-prop-type';

import { Membership } from './Membership';

export const RequestedMembershipSection = ({
  requestedMemberships,
  removeMembership,
  chatChannelAcceptMembership,
  currentMembershipRole,
}) => {
  if (currentMembershipRole === 'member') {
    return null;
  }

  return (
    <div
      data-testid="requested-memberships"
      className="p-4 grid gap-2 crayons-card mb-4"
      data-requested-count={
        requestedMemberships ? requestedMemberships.length : 0
      }
    >
      <h3 className="mb-2 requested_memberships">Joining Request</h3>
      {requestedMemberships && requestedMemberships.length > 0
        ? requestedMemberships.map((pendingMembership) => (
            <Membership
              membership={pendingMembership}
              removeMembership={removeMembership}
              chatChannelAcceptMembership={chatChannelAcceptMembership}
              membershipType="requested"
              currentMembershipRole={currentMembershipRole}
            />
          ))
        : null}
    </div>
  );
};

RequestedMembershipSection.propTypes = {
  requestedMemberships: PropTypes.arrayOf(defaultMembershipPropType).isRequired,
  removeMembership: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.func.isRequired,
};
