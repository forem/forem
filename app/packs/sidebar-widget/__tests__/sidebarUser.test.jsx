import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { SidebarUser } from '../sidebarUser';

function getUser() {
  return {
    id: 1234,
    username: 'john_doe',
    name: 'Jon Doe',
    profile_image_url: 'www.profile.com',
  };
}

describe('<SidebarUser />', () => {
  it('should have no a11y violations', async () => {
    const user = getUser();

    const { container } = render(
      <SidebarUser
        key={user.id}
        user={user}
        followUser={jest.fn()}
        index={0}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders properly', () => {
    const user = getUser();
    const { getByTestId, getByText, getByAltText } = render(
      <SidebarUser
        key={user.id}
        user={user}
        followUser={jest.fn()}
        index={0}
      />,
    );

    expect(getByTestId('widget-avatar').getAttribute('href')).toEqual(
      '/john_doe',
    );
    getByAltText('Jon Doe');
    expect(getByAltText('Jon Doe').getAttribute('src')).toEqual(
      'www.profile.com',
    );

    getByText('Jon Doe');
    expect(getByText('Jon Doe').getAttribute('href')).toEqual('/john_doe');
  });

  it('triggers the onClick', () => {
    const user = getUser();
    const followUser = jest.fn();
    const { getByTestId } = render(
      <SidebarUser
        key={user.id}
        user={user}
        followUser={followUser}
        index={0}
      />,
    );

    getByTestId('widget-follow-button').click();

    expect(followUser).toHaveBeenCalled();
  });

  describe('following', () => {
    it('shows if the user is followed', () => {
      const user = getUser();
      user.following = true;

      const { queryByText } = render(
        <SidebarUser
          key={user.id}
          user={user}
          followUser={jest.fn()}
          index={0}
        />,
      );

      expect(queryByText(/Following/i)).toBeDefined();
    });

    it('shows if the user can be followed', () => {
      const user = getUser();
      user.following = false;

      const { queryByText } = render(
        <SidebarUser
          key={user.id}
          user={user}
          followUser={jest.fn()}
          index={0}
        />,
      );

      expect(queryByText(/follow/i)).toBeDefined();
    });
  });
});
