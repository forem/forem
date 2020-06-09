import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import RequestedMembershipSection from '../ChatChannelSettings/RequestedMembershipSection';

const data = {
  requested_memberships: [],
  currentMembershipRole: 'mod',
};

const getRequestedMembershipSection = (membershipData) => (
  <RequestedMembershipSection
    requested_memberships={membershipData.requested_memberships}
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
});
