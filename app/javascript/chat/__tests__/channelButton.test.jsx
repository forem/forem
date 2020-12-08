import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import ChannelButton from '../components/ChannelButton';

const getChannel = () => {
  return {
    channel_name: 'test',
    channel_color: '#00FFFF',
    channel_type: 'invite_only',
    channel_modified_slug: '@test34',
    id: 34,
    chat_channel_id: 23,
    status: 'active',
  };
};

describe('<ChannelButton />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<ChannelButton channel={getChannel()} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { getByText } = render(<ChannelButton channel={getChannel()} />);
    const button = getByText('test');

    expect(button.dataset.channelSlug).toEqual('@test34');
    expect(button.dataset.channelId).toEqual('23');
    expect(button.dataset.channelStatus).toEqual('active');
    expect(button.dataset.channelName).toEqual('test');
    expect(button.dataset.content).toEqual('sidecar-channel-request');
  });
});
