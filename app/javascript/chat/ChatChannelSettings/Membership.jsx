import { h } from 'preact';
import PropTypes from 'prop-types';

const Membership = ({
  membership,
  removeMembership,
  membershipType,
  chatChannelAcceptMembership,
  currentMembershipRole,
}) => {
  return (
    <div className="flex items-center">
      <a href={`/${membership.username}`} title={`${membership.name} profile`}>
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
        <button
          className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost add-membership"
          type="button"
          onClick={chatChannelAcceptMembership}
          data-membership-id={membership.membership_id}
        >
          +
        </button>
      ) : null}
      {membership.role !== 'mod' && currentMembershipRole === 'mod' ? (
        <button
          className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost remove-membership"
          type="button"
          onClick={removeMembership}
          data-membership-id={membership.membership_id}
          data-membership-status={membership.status}
        >
          x
        </button>
      ) : null}
    </div>
  );
};

Membership.propTypes = {
  membership: PropTypes.objectOf(
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
  membershipType: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.string.isRequired,
};

export default Membership;
