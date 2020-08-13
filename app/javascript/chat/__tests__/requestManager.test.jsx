import { h } from 'preact';
import { render } from '@testing-library/preact';
import RequestManager from '../RequestManager/RequestManager';

const data = [
  {
    resource: {},
  },
];

describe('<RequestManager />', () => {
  it('should have the proper elements', () => {
    const { queryByText } = render(
      <RequestManager resource={data} updateRequestCount={jest.fn()} />,
    );

    expect(
      queryByText('You have no pending invitations/Joining Requests.'),
    ).toBeDefined();
  });
});
