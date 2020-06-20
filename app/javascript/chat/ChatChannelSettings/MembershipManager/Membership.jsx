import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

const CogIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width="24"
    height="24"
    role="img"
    aria-labelledby="ai2ols8ka2ohfp0z568lj68ic2du21s"
    className="crayons-icon"
  >
    <title id="ai2ols8ka2ohfp0z568lj68ic2du21s">Preferences</title>
    <path d="M12 1l9.5 5.5v11L12 23l-9.5-5.5v-11L12 1zm0 2.311L4.5 7.653v8.694l7.5 4.342 7.5-4.342V7.653L12 3.311zM12 16a4 4 0 110-8 4 4 0 010 8zm0-2a2 2 0 100-4 2 2 0 000 4z" />
  </svg>
);

const Membership = ({
  membership,
  currentMembership,
  removeMembership,
  handleUpdateMembershipRole,
}) => {
  const addAsModButton =
    membership.role === 'member' ? (
      <button
        className="crayons-btn crayons-btn--ghost remove-membership"
        type="button"
        onClick={handleUpdateMembershipRole}
        data-membership-id={membership.membership_id}
        data-role="mod"
      >
        Add as Mode
      </button>
    ) : null;

  const addAsMemberButton =
    membership.role === 'mod' ? (
      <button
        className="crayons-btn crayons-btn--ghost remove-membership"
        type="button"
        onClick={handleUpdateMembershipRole}
        data-membership-id={membership.membership_id}
        data-role="member"
      >
        Add as Member
      </button>
    ) : null;

  const removeMembershipButton =
    membership.role === 'member' ? (
      <button
        className="crayons-btn crayons-btn--ghost  crayons-btn--ghost-danger remove-membership"
        type="button"
        onClick={removeMembership}
        data-membership-id={membership.membership_id}
        data-membership-status={membership.status}
      >
        Remove
      </button>
    ) : null;

  const dropdown =
    currentMembership.role === 'mod' ? (
      <div className="membership-actions">
        <span className="membership-management__dropdown-button">
          <Button
            variant="outlined"
            icon={CogIcon}
            contentType="icon"
            onClick={(_event) => {}}
          />
        </span>

        <div className="membership-management__dropdown-memu">
          {addAsModButton}
          {addAsMemberButton}
          {removeMembershipButton}
        </div>
      </div>
    ) : null;

  return (
    <div className="flex items-center my-3 member-list-item">
      <a href={`/${membership.username}`}>
        <span className="crayons-avatar crayons-avatar--l mr-3">
          <img
            className="crayons-avatar__image align-middle"
            role="presentation"
            src={membership.image}
            alt={`${membership.name} profile`}
          />
        </span>
        <span className="mr-2 user_name">{membership.name}</span>
      </a>
      {dropdown}
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
  currentMembership: PropTypes.isRequired,
  removeMembership: PropTypes.func.isRequired,
  handleUpdateMembershipRole: PropTypes.func.isRequired,
};

export default Membership;
