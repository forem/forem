import { h } from 'preact';
import render from 'preact-render-to-json';
import OnboardingFollowUsers from '../OnboardingFollowUsers';

describe('<OnboardingFollowUsers />', () => {
  it('renders properly when given users', () => {
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
    const tree = render(
      <OnboardingFollowUsers
        users={users}
        checkedUsers={checkedUsers}
        handleCheckUser={handleCheckUser}
        handleCheckAllUsers={handleCheckAllUsers}
      />,
    );
    expect(tree).toMatchSnapshot();
  });
});
