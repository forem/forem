import { h } from 'preact';
import { render } from '@testing-library/preact';
import SidebarUser from '../sidebarUser';

const user = {
  id: 1234,
  username: 'john_doe',
  name: 'Jon Doe',
  profile_image_url: 'www.profile.com'
};

const followUser = jest.fn();

const renderedSideBar = props =>
  render(
    <SidebarUser
      key={user.id}
      user={user}
      followUser={followUser}
      index={0}
      {...props}
    />,
  );

describe('<SidebarUser />', () => {
  it('renders properly', () => {
    const { getByTestId, getByText, getByAltText } = renderedSideBar();

    expect(getByTestId('widget-avatar').getAttribute('href')).toEqual('/john_doe');
    getByAltText('Jon Doe');
    expect(getByAltText('Jon Doe').getAttribute('src')).toEqual('www.profile.com');

    getByText('Jon Doe');
    expect(getByText('Jon Doe').getAttribute('href')).toEqual('/john_doe');
  });

  it('triggers the onClick', () => {
    const { getByTestId, getByText, getByAltText } = renderedSideBar();
    getByTestId('widget-follow-button').click();

    expect(followUser).toHaveBeenCalled();
  });

  describe('following', () => {
    it('shows if the user is followed', () => {
      const { getByText } = renderedSideBar({ user: { following: true } });
      getByText(/Following/i);
    });

    it('shows if the user can be followed', () => {
      const { getByText } = renderedSideBar({ user: { following: false } });
      getByText(/follow/i);
    });

  });
});
