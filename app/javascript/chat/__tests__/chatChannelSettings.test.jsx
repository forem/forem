import { h } from 'preact';
import render from 'preact-render-to-json';
import ChatChannelSettings from '../ChatChannelSettings/ChatChannelSettings';

const channelDetails = {
  data: {},
  activeMembershipId: 12,
};

const getChatChannelSettinsg = (resource) => (
  <ChatChannelSettings
    resource={resource.data}
    activeMembershipId={resource.activeMembershipId}
  />
);

describe('<ChatChannelSettings />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getChatChannelSettinsg(channelDetails));
    expect(tree).toMatchSnapshot();
  });
});
