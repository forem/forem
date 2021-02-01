import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ChannelRequestSection } from '../RequestManager/ChannelRequestSection';

const data = {
  channelRequests: [
    {
      name: 'Demo name',
      membership_id: 11,
      user_id: 10,
      role: 'member',
      image: '/image',
      username: 'demousername',
      status: 'joining_request',
      chat_channel_name: 'demo channel',
    },
  ],
};

describe('<ChannelRequestSection />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <ChannelRequestSection channelRequests={data.channelRequests} />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the the component', () => {
    const { getByTestId } = render(
      <ChannelRequestSection channelRequests={data.channelRequests} />,
    );

    const channelRequestsWrapper = getByTestId('chat-channel-joining-request');
    expect(
      Number(channelRequestsWrapper.dataset.activeCount),
    ).toBeGreaterThanOrEqual(1);
  });
});
