import { h } from 'preact';
import PropTypes from 'prop-types';
import OnboardingUsers from './OnboardingUsers';

const OnboardingFollowUsers = ({
  users,
  checkedUsers,
  handleCheckUser,
  handleCheckAllUsers,
}) => (
  <OnboardingUsers
    users={users}
    checkedUsers={checkedUsers}
    handleCheckUser={handleCheckUser}
    handleCheckAllUsers={handleCheckAllUsers}
  />
);

OnboardingFollowUsers.propTypes = {
  users: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number,
      name: PropTypes.string,
      summary: PropTypes.string,
      profile_image_url: PropTypes.string,
    }),
  ).isRequired,
  checkedUsers: PropTypes.arrayOf(PropTypes.object).isRequired,
  handleCheckUser: PropTypes.func.isRequired,
  handleCheckAllUsers: PropTypes.func.isRequired,
};

export default OnboardingFollowUsers;
