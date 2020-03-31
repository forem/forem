import { h } from 'preact';
import { shallow } from 'preact-render-spy';
import render from 'preact-render-to-json';
import SidebarUser from '../sidebarUser';

const user = {
  id: 1234,
};
const followUser = jest.fn();

const renderedSideBar = props =>
  shallow(
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
    const tree = render(
      <SidebarUser
        key={user.id}
        user={user}
        followUser={followUser}
        index={0}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('triggers the onClick', () => {
    renderedSideBar()
      .find('.widget-list-item__follow-button')
      .simulate('click');
    expect(followUser).toHaveBeenCalled();
  });

  it('shows if the user is followed or not', () => {
    expect(
      renderedSideBar({ user: { following: true } }).contains('✓ FOLLOWING'),
    ).toBe(true);
    expect(
      renderedSideBar({ user: { following: false } }).contains('+ FOLLOW'),
    ).toBe(true);
  });
});
