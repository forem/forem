import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import PendingMembershipSections from '../ChatChannelSettings/PendingMembershipSection';

const data = {
  pendingMemberships: [],
  currentMembershipRole: 'mod',
};

const membership = {
  pendingMemberships: [
    {
      name: 'test user',
      username: 'testusername',
      user_id: '1',
      membership_id: '2',
      role: 'member',
      status: 'pending',
      image: '',
    },
  ],
  membershipType: 'pending',
  currentMembershipRole: 'mod',
};

const getPendingMembershipSections = (membershipData) => (
  <PendingMembershipSections
    pendingMemberships={membershipData.pendingMemberships}
    currentMembershipRole={membershipData.currentMembershipRole}
  />
);

describe('<PendingMembershipSections />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getPendingMembershipSections(data));
    expect(tree).toMatchSnapshot();
  });

  it('should have the elements', () => {
    const context = shallow(getPendingMembershipSections(data));

    expect(context.find('.pending_memberships').exists()).toEqual(true);
  });

  it('should not render the membership list', () => {
    const context = shallow(getPendingMembershipSections(data));

    expect(context.find('.membership-list').exists()).toEqual(false);
  });

  it('should render the membership list', () => {
    const context = shallow(getPendingMembershipSections(membership));

    expect(context.find('.pending-member').exists()).toEqual(true);
  });
});
