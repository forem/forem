import { h } from 'preact';
import PropTypes from 'prop-types';
import { PendingInvitationListItem } from './PersonalInvitationListItem';

export const PersonalInvitationSection = ({
  userInvitations,
  updateMembership,
}) => {
  if (!userInvitations || userInvitations?.length < 0) {
    return null;
  }

  return (
    <div
      data-testid="user-invitations"
      data-active-count={userInvitations ? userInvitations.length : 0}
    >
      {userInvitations &&
        userInvitations.map((userInvitation) => {
          return (
            <PendingInvitationListItem
              request={userInvitation}
              updateMembership={updateMembership}
            />
          );
        })}
    </div>
  );
};

PersonalInvitationSection.propTypes = {
  userInvitations: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
      membership_id: PropTypes.number.isRequired,
      user_id: PropTypes.number.isRequired,
      role: PropTypes.string.isRequired,
      image: PropTypes.string.isRequired,
      username: PropTypes.string.isRequired,
      status: PropTypes.string.isRequired,
      channel_name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  updateMembership: PropTypes.func.isRequired,
};
