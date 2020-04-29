import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ChannelButton from '../components/channelButton';

const chnl = {
  channel_name: 'test',
  channel_color: '#00FFFF',
  channel_type: 'invite_only',
  channel_modified_slug: '@test34',
  id: 34,
  chat_channel_id: 23,
  status: 'active',
};

const getChannel = (channel) => <ChannelButton channel={channel} />;

describe('<Message />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getChannel(chnl));
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper elements, attributes and values', () => {
    const context = shallow(getChannel(chnl));
    expect(
      context.find('.chatchanneltabbutton').attr('data-channel-slug'),
    ).toEqual(chnl.channel_modified_slug); // check user
    expect(context.find('.chatchanneltabbutton').text()).toEqual(
      chnl.channel_name,
    );
  });
});
