import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ActiveMembershipsSection from '../ChatChannelSettings/ActiveMembershipsSection';

const data = {
  activeMemberships: [],
  currentMembershipRole: 'mod'
}

const getActiveMembershipsSection = (membershipData) => (
  <ActiveMembershipsSection 
    activeMemberships={membershipData.activeMemberships}
    currentMembershipRole={membershipData.currentMembershipRole}
  />
)

describe('<ActiveMembershipsSection />', () => {
  it("should render and test snapshot", () => {
    const tree = render(getActiveMembershipsSection(data));
    expect(tree).toMatchSnapshot();
  })

  it("should have the elements", () => {
    const context = shallow(getActiveMembershipsSection(data));

    expect(context.find('.active_members').exists()).toEqual(true)
  })
})