import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import Membership from '../ChatChannelSettings/Membership';

const modUser = {
  membership: {
    name: 'test user',
    username: 'testusername',
    user_id: '1',
    membership_id: '2',
    role: 'mod',
    status: 'active',
    image: '',
  },
  membershipType: 'active',
  currentMembershipRole: 'mod',
};

const memberUser = {
  membership: {
    name: 'test user',
    username: 'testusername',
    user_id: '1',
    membership_id: '2',
    role: 'member',
    status: 'active',
    image: '',
  },
  membershipType: 'requested',
  currentMembershipRole: 'mod',
};

const getMembership = (membershipData) => (
  <Membership
    membership={membershipData.membership}
    membershipType={membershipData.membershipType}
    currentMembershipRole={membershipData.currentMembershipRole}
  />
);

describe('<Membership />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getMembership(modUser));
    expect(tree).toMatchSnapshot();
  });

  it('should have the element', () => {
    const context = shallow(getMembership(modUser));
    expect(context.find('.user_name').exists()).toEqual(true);
  });

  it('should have the the same ame', () => {
    const context = shallow(getMembership(modUser));

    expect(context.find('.user_name').text()).toEqual(modUser.membership.name);
  });

  it('should not visible remove and add membership button', () => {
    const context = shallow(getMembership(modUser));

    expect(context.find('.remove-membership').exists()).toEqual(false);
    expect(context.find('.add-membership').exists()).toEqual(false);
  });

  it('should add button visible', () => {
    const context = shallow(getMembership(memberUser));
    expect(context.find('.add-membership').exists()).toEqual(true);
    expect(context.find('.remove-membership').exists()).toEqual(true);
  });
});
