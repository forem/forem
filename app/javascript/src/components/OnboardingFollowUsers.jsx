import { h } from 'preact';
import PropTypes from 'prop-types';
import OnboardingUsers from './OnboardingUsers';
import userPropType from './common-prop-types/user-prop-types';

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
  users: PropTypes.arrayOf(userPropType).isRequired,
  checkedUsers: PropTypes.arrayOf(PropTypes.object).isRequired,
  handleCheckUser: PropTypes.func.isRequired,
  handleCheckAllUsers: PropTypes.func.isRequired,
};

export default OnboardingFollowUsers;
