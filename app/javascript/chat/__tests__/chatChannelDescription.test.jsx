import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import ChannelDescriptionSection from '../ChatChannelSettings/ChannelDescriptionSection';

describe('<ChannelDescriptionSection />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <ChannelDescriptionSection
        channelName="some name"
        channelDescription="some description"
        currentMembershipRole="mod"
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { getByText } = render(
      <ChannelDescriptionSection
        channelName="some name"
        channelDescription="some description"
        currentMembershipRole="member"
      />,
    );

    getByText('some name');
    getByText('some description');
    getByText('You are a channel member');
  });
});
