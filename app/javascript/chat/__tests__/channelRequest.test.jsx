import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import ChannelRequest from '../channelRequest';

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
    const { getByText, getByAltText } = render(
      <ChannelRequest resource={getResource()} />,
    );

    getByText('Hey Sarthak !');
    getByText(
      'You are not a member of this group yet. Send a request to join.',
    );
    getByAltText('sarthak9 profile');
    getByAltText('IronMan profile');
    getByText('Join IronMan', { selector: 'button' });
  });
});
