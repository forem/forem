import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import PendingMembershipSections from '../ChatChannelSettings/PendingMembershipSection';

const data = {
  pendingMemberships: [],
  currentMembershipRole: 'mod'
}

const getPendingMembershipSections = (membershipData) => (
  <PendingMembershipSections 
    pendingMemberships={membershipData.pendingMemberships}
    currentMembershipRole={membershipData.currentMembershipRole}
  />
)

describe('<PendingMembershipSections />', () => {
  it("should render and test snapshot", () => {
    const tree = render(getPendingMembershipSections(data));
    expect(tree).toMatchSnapshot();
  })

  it("should have the elements", () => {
    const context = shallow(getPendingMembershipSections(data));

    expect(context.find('.pending_memberships').exists()).toEqual(true)
  })
})