import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import { axe } from 'jest-axe';
import { beforeEach } from '@jest/globals';
import { RequestManager } from '../RequestManager/RequestManager';
import '@testing-library/jest-dom';

function getData() {
  const data = [
    {
      resource: {},
    },
  ];

  return data;
}

// TODO: There needs to be some better tests in here in regards to different data: empty, some data etc.
describe('<RequestManager />', () => {
  beforeEach(() => {
    const csrfToken = 'this-is-a-csrf-token';

    window.fetch = fetch;
    window.getCsrfToken = async () => csrfToken;

    fetch.mockResponse(
      JSON.stringify({
        result: { user_joining_requests: [], channel_joining_memberships: [] },
      }),
    );
  });

  it('should have no a11y violations', async () => {
    const { container } = render(
      <RequestManager resource={getData()} updateRequestCount={jest.fn()} />,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have the proper elements', () => {
    const { getByText } = render(
      <RequestManager resource={getData()} updateRequestCount={jest.fn()} />,
    );

    expect(getByText('You have no pending invitations.')).toBeInTheDocument();
  });
});
