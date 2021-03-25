import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ChannelRequest } from '../channelRequest';

const getResource = () => {
  return {
    user: {
      name: 'Sarthak',
      username: 'sarthak9',
    },
    channel: {
      name: 'IronMan',
    },
  };
};

describe('<ChannelRequest />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<ChannelRequest resource={getResource()} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByText, queryByAltText } = render(
      <ChannelRequest resource={getResource()} />,
    );

    expect(queryByText('Hey Sarthak !')).toBeDefined();
    expect(
      queryByText(
        'You are not a member of this group yet. Send a request to join.',
      ),
    ).toBeDefined();
    expect(queryByAltText('sarthak9 profile')).toBeDefined();
    expect(queryByAltText('IronMan profile')).toBeDefined();
    expect(queryByText('Join IronMan', { selector: 'button' })).toBeDefined();
  });
});
