import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultMembershipPropType } from '../../common-prop-types/membership-prop-type';
import { Button } from '@crayons';

export const Membership = ({
  membership,
  removeMembership,
  membershipType,
  chatChannelAcceptMembership,
  currentMembershipRole,
}) => {
  return (
    <div className="flex items-center">
      <a
        href={`/${membership.username}`}
        className="chatmessagebody__username--link"
        target="_blank"
        rel="noopener noreferrer"
        data-content="sidecar-user"
      >
        <span className="crayons-avatar crayons-avatar--l mr-3">
          <img
            className="crayons-avatar__image align-middle"
            src={membership.image}
            alt={`${membership.name} profile`}
          />
        </span>
        <span className="mr-2 user_name">{membership.name}</span>
      </a>
      {membershipType === 'requested' ? (
        <Button
          className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost add-membership"
          type="button"
          onClick={chatChannelAcceptMembership}
          data-membership-id={membership.membership_id}
        >
          +
        </Button>
      ) : null}
      {membership.role !== 'mod' && currentMembershipRole === 'mod' ? (
        <Button
          className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost remove-membership"
          type="button"
          onClick={removeMembership}
          data-membership-id={membership.membership_id}
          data-membership-status={membership.status}
        >
          x
        </Button>
      ) : null}
    </div>
  );
};

Membership.propTypes = {
  membership: PropTypes.objectOf(defaultMembershipPropType).isRequired,
  removeMembership: PropTypes.func.isRequired,
  membershipType: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.string.isRequired,
};
