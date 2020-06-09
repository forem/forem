import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import Membership from '../ChatChannelSettings/Membership';

const data = {
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

const getMembership = (membershipData) => (
  <Membership
    membership={membershipData.membership}
    membershipType={membershipData.membershipType}
    currentMembershipRole={membershipData.currentMembershipRole}
  />
);

describe('<Membership />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getMembership(data));
    expect(tree).toMatchSnapshot();
  });

  it('should have the elements', () => {
    const context = shallow(getMembership(data));

    expect(context.find('.user_name').text()).toEqual(data.membership.name);
  });
});
