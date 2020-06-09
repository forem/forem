import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import LeaveMembershipSection from '../ChatChannelSettings/LeaveMembershipSection';

const data = {
  currentMembershipRole: 'member',
};

const modUser = {
  currentMembershipRole: 'mod',
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

  it('should have the leave button', () => {
    const context = shallow(getLeaveMembershipSection(data));
    expect(context.find('.leave_button').text()).toEqual('Leave Channel');
  });

  it('should not render', () => {
    const context = shallow(getLeaveMembershipSection(modUser));
    expect(context.find('.leave_membership_section').exists()).toEqual(false);
  });
});
