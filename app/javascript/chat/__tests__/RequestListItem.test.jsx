import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { RequestListItem } from '../RequestManager/RequestListItem';

const data = {
  request: {
    name: 'Demo name',
    membership_id: 11,
    user_id: 10,
    role: 'member',
    image: '/image',
    username: 'demousername',
    status: 'joining_request',
    chat_channel_name: 'demo channel',
  },
};

describe('<RequestListItem />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<RequestListItem request={data.request} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the the component', () => {
    const { queryByText } = render(<RequestListItem request={data.request} />);

    expect(
      queryByText(
        `${data.request.name} wants to join ${data.request.chat_channel_name}`,
      ),
    ).toBeDefined();

    expect(queryByText('Reject', { selector: 'button' })).toBeDefined();

    expect(queryByText('Accept', { selector: 'button' })).toBeDefined();
  });
});
