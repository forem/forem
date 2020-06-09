import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import RequestedMembershipSection from '../ChatChannelSettings/RequestedMembershipSection';

const data = {
  requestedMemberships: [],
  currentMembershipRole: 'mod',
};

const membership = {
  requestedMemberships: [
    {
      name: 'test user',
      username: 'testusername',
      user_id: '1',
      membership_id: '2',
      role: 'member',
      status: 'requested',
      image: '',
    },
  ],
  membershipType: 'requested',
  currentMembershipRole: 'mod',
};

const getRequestedMembershipSection = (membershipData) => (
  <RequestedMembershipSection
    requestedMemberships={membershipData.requestedMemberships}
    currentMembershipRole={membershipData.currentMembershipRole}
  />
);

describe('<RequestedMembershipSection />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getRequestedMembershipSection(data));
    expect(tree).toMatchSnapshot();
  });

  it('should have the elements', () => {
    const context = shallow(getRequestedMembershipSection(data));

    expect(context.find('.requested_memberships').exists()).toEqual(true);
  });

  it('should not render the membership list', () => {
    const context = shallow(getRequestedMembershipSection(data));

    expect(context.find('.items-center').exists()).toEqual(false);
  });

  it('should render the membership list', () => {
    const context = shallow(getRequestedMembershipSection(membership));

    expect(context.find('.requested-member').exists()).toEqual(true);
  });
});
