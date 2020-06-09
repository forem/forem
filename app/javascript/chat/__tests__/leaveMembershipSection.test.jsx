import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import LeaveMembershipSection from '../ChatChannelSettings/LeaveMembershipSection';

const data = {
  currentMembershipRole: 'member',
};

const getLeaveMembershipSection = (membershipData) => (
  <LeaveMembershipSection
    currentMembershipRole={membershipData.currentMembershipRole}
  />
);

describe('<LeaveMembershipSection />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getLeaveMembershipSection(data));
    expect(tree).toMatchSnapshot();
  });

  it('should have the elements', () => {
    const context = shallow(getLeaveMembershipSection(data));

    expect(context.find('.leave_membership_section').exists()).toEqual(true);
  });
});
