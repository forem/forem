import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ActiveMembershipsSection from '../ChatChannelSettings/ActiveMembershipsSection';

const data = {
  activeMemberships: [],
  currentMembershipRole: 'mod',
};

const membership = {
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
  membershipType: 'active',
  currentMembershipRole: 'mod',
};

const getActiveMembershipsSection = (membershipData) => (
  <ActiveMembershipsSection
    activeMemberships={membershipData.activeMemberships}
    currentMembershipRole={membershipData.currentMembershipRole}
  />
);

describe('<ActiveMembershipsSection />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getActiveMembershipsSection(data));
    expect(tree).toMatchSnapshot();
  });

  it('should have the elements', () => {
    const context = shallow(getActiveMembershipsSection(data));

    expect(context.find('.active_members').exists()).toEqual(true);
  });

  it('should have title', () => {
    const context = shallow(getActiveMembershipsSection(data));

    expect(context.find('.active_members').text()).toEqual('Members');
  });

  it('should not render the membership list', () => {
    const context = shallow(getActiveMembershipsSection(data));

    expect(context.find('.items-center').exists()).toEqual(false);
  });

  it('should render the membership list', () => {
    const context = shallow(getActiveMembershipsSection(membership));

    expect(context.find('.active-member').exists()).toEqual(true);
  });
});
