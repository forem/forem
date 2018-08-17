import { h } from 'preact';
import { shallow } from 'preact-render-spy';
import { render } from 'preact-render-to-json';
import OnboardingUsers from '../OnboardingUsers';

describe('<OnboardingUsers />', () => {
  const users = [
    {
      id: 1,
      name: 'Ben Halpern',
      profile_image_url: 'ben.jpg',
    },
    {
      id: 2,
      name: 'Krusty the Clown',
      profile_image_url: 'clown.jpg',
    },
    {
      id: 3,
      name: 'dev.to staff',
      profile_image_url: 'dev.jpg',
    },
  ];
  const checkedUsers = [
    {
      id: 1,
      name: 'Ben Halpern',
      profile_image_url: 'ben.jpg',
    },
    {
      id: 2,
      name: 'Krusty the Clown',
      profile_image_url: 'clown.jpg',
    },
    {
      id: 3,
      name: 'dev.to staff',
      profile_image_url: 'dev.jpg',
    },
  ];
  const handleCheckUser = jest.fn();
  const handleCheckAllUsers = jest.fn();

  describe('when given users to follow', () => {
    it('renders correctly', () => {
      const context = render(
        <OnboardingUsers
          users={users}
          checkedUsers={checkedUsers}
          handleCheckUser={handleCheckUser}
          handleCheckAllUsers={handleCheckAllUsers}
        />,
      );
      expect(context).toMatchSnapshot();
    });

    it('responds to clicking Follow All', () => {
      const context = shallow(
        <OnboardingUsers
          users={users}
          checkedUsers={checkedUsers}
          handleCheckUser={handleCheckUser}
          handleCheckAllUsers={handleCheckAllUsers}
        />,
      );
      expect(context.find('#onboarding-user-follow-all-btn').text()).toEqual(
        '✓',
      );
      context.find('#onboarding-user-follow-all-btn').simulate('click');
      expect(handleCheckAllUsers).toHaveBeenCalledTimes(1);
    });
  });
});
