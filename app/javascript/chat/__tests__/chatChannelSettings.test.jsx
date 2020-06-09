import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
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

  it('should not render if not channel', () => {
    const context = shallow(getChatChannelSettinsg(channelDetails));
    expect(context.find('.channel_settings').exists()).toEqual(false);
  });
});
