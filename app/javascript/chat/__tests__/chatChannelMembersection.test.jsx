import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ChatChannelMembershipSection from '../ChatChannelSettings/ChatChannelMembershipSection';

const data = {
  pendingMemberships: [],
  requestedMemberships: [],
  activeMemberships: []
}

const getChatChannelMembershipSection = (memberships) => {
  return (
    <ChatChannelMembershipSection 
      pendingMemberships={memberships.pendingMemberships}
      requestedMemberships={memberships.requestedMemberships}
      activeMemberships={memberships.activeMemberships}
    />
  )
}

describe('<ChatChannelMembershipSection />', () => {
  it ('should render and test snapshot', () => {
    const tree = render(getChatChannelMembershipSection(data));
    expect(tree).toMatchSnapshot();
  })

  it ('should have the proper elements, attributes and values', () => {
    const context = shallow(getChatChannelMembershipSection(data));


    expect(context.find('.membership-list').exists()).toEqual(true)
  })
})