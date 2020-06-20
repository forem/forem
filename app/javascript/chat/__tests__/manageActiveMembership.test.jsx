import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ManageActiveMembership from '../ChatChannelSettings/MembershipManager/ManageActiveMembership';

const data = {
  currentMembership: {
    role: 'mod',
    user_id: 1,
    chat_channel_id: 1,
    id: 2,
    status: 'active',
  },
  activeMemberships: [
    {
      name: 'test user',
      username: 'testusername',
      user_id: '1',
      membership_id: '2',
      role: 'mod',
      status: 'active',
      image: '',
    },
  ],
  invitationLink: 'https://dummy.com',
};

const getManageActiveMembership = (resource) => (
  <ManageActiveMembership
    currentMembership={resource.currentMembership}
    activeMemberships={resource.activeMemberships}
    invitationLink={resource.invitationLink}
  />
);

describe('<ManageActiveMembership />', () => {
  it('should render & test snapshot', () => {
    const tree = render(getManageActiveMembership(data));
    expect(tree).toMatchSnapshot();
  });

  it('should render the active membership', () => {
    const context = shallow(getManageActiveMembership(data));
    expect(context.find('.membership-manager').exists()).toEqual(true);
  });

  it('should render the active membership title', () => {
    const context = shallow(getManageActiveMembership(data));
    expect(context.find('.chat_channel-member-list').exists()).toEqual(true);
  });
});
