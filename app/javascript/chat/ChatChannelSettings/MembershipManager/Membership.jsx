import { h } from 'preact';
import PropTypes from 'prop-types';
import adminEmoji from '../../../../assets/images/twemoji/fire.svg';
import { Button } from '@crayons';

export const Membership = ({
  membership,
  currentMembership,
  removeMembership,
  handleUpdateMembershipRole,
  showActionButton,
}) => {
  const addAsModButton =
    membership.role === 'member' ? (
      <Button
        type="button"
        size="s"
        onClick={handleUpdateMembershipRole}
        data-membership-id={membership.membership_id}
        data-role="mod"
      >
        Promote to Mod
      </Button>
    ) : null;

  const addAsMemberButton =
    membership.role === 'mod' ? (
      <Button
        type="button"
        size="s"
        onClick={handleUpdateMembershipRole}
        data-membership-id={membership.membership_id}
        data-role="member"
      >
        Remove Mod
      </Button>
    ) : null;

  const removeMembershipButton =
    membership.role === 'member' ? (
      <Button
        type="button"
        size="s"
        variant="ghost-danger"
        onClick={removeMembership}
        data-membership-id={membership.membership_id}
        data-membership-status={membership.status}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 32.526 32.526"
          width="18"
          height="18"
          className="crayons-icon"
          data-membership-id={membership.membership_id}
          data-membership-status={membership.status}
        >
          <path
            fill="#4f5458"
            data-membership-id={membership.membership_id}
            data-membership-status={membership.status}
            d="M32.526 2.828L29.698 0 16.263 13.435 2.828 0 0 2.828l13.435 13.435L0 29.698l2.828 2.828 13.435-13.435 13.435 13.435 2.828-2.828-13.435-13.435z"
          />
        </svg>
      </Button>
    ) : null;

  const dropdown =
    currentMembership.role === 'mod' && showActionButton ? (
      <span className="membership-actions">
        {removeMembershipButton}
        {addAsModButton}
        {addAsMemberButton}
      </span>
    ) : null;

  return (
    <div className="flex items-center my-3 member-list-item justify-content-between">
      <div className="">
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
      <div className="">{dropdown}</div>
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
  showActionButton: PropTypes.bool.isRequired,
};
