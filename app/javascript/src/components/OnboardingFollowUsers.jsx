import { h } from 'preact';
import OnboardingUsers from './OnboardingUsers';

const OnboardingFollowUsers = ({ users, checkedUsers, handleCheckUser, handleCheckAllUsers }) => (
  <OnboardingUsers
    users={users}
    checkedUsers={checkedUsers}
    handleCheckUser={handleCheckUser}
    handleCheckAllUsers={handleCheckAllUsers}
  />
);

export default OnboardingFollowUsers;
