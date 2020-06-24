import { h } from 'preact';
import PropTypes from 'prop-types';

import ConfigImage from '../../../../assets/images/three-dots.svg';
import adminEmoji from '../../../../assets/images/emoji/apple-fire.png';

const Membership = ({
  membership,
  currentMembership,
  removeMembership,
  handleUpdateMembershipRole,
}) => {
  const addAsModButton =
    membership.role === 'member' ? (
      <button
        className="crayons-btn crayons-btn--ghost remove-membership p-2"
        type="button"
        onClick={handleUpdateMembershipRole}
        data-membership-id={membership.membership_id}
        data-role="mod"
      >
        Add as Mod
        <span>
          <img
            src={adminEmoji}
            alt="admin emoji"
            data-content="admin emoji"
            className="admin-emoji-button mx-2"
            title="MOD"
          />
        </span>
      </button>
    ) : null;

  const addAsMemberButton =
    membership.role === 'mod' ? (
      <button
        className="crayons-btn crayons-btn--ghost remove-membership p-2"
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
        className="crayons-btn crayons-btn--ghost  crayons-btn--ghost-danger remove-membership p-2"
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
          <img
            src={ConfigImage}
            alt="channel config"
            data-content="drop-down-image"
            className="w-25"
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
    <div className="flex items-center my-3 member-list-item justify-content-between">
      <div className="w-100">
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
              role="presentation"
              src={membership.image}
              alt={`${membership.name} profile`}
            />
          </span>
          <span className="mr-2 user_name">{membership.name}</span>
          <span>
            {membership.role === 'mod' ? (
              <img
                src={adminEmoji}
                alt="admin emoji"
                data-content="admin emoji"
                className="admin-emoji"
                title="MOD"
              />
            ) : null}
          </span>
        </a>
      </div>
      <div className="flex-shrink-1">{dropdown}</div>
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
