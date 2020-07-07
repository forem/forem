import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import RequestManager from '../requestManager';

const data = [
  {
    id: 2,
    channel_name: 'ironman',
  },
];

describe('<RequestManager />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <RequestManager
        resource={data}
        handleRequestRejection={jest.fn()}
        handleRequestApproval={jest.fn()}
      />,
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should have the proper elements', () => {
    const { getByTestId, getByText } = render(
      <RequestManager
        resource={data}
        handleRequestRejection={jest.fn()}
        handleRequestApproval={jest.fn()}
      />,
    );

    getByText(/Joining Request/i);
    getByText(/Manage request coming to all the channels/i);
    const request = getByTestId('request');
    expect(request.textContent).toContain('Reject');
    expect(request.textContent).toContain('Accept');
  });

  it('should call the relavant handlers when the buttons are clicked', async () => {
    const handleRequestRejection = jest.fn();
    const handleRequestApproval = jest.fn();

    const { getByText } = render(
      <RequestManager
        resource={data}
        handleRequestRejection={handleRequestRejection}
        handleRequestApproval={handleRequestApproval}
      />,
    );
    const rejectButton = getByText(/reject/i);
    const acceptButton = getByText(/accept/i);

    rejectButton.click();

    expect(handleRequestRejection).toHaveBeenCalledTimes(1);

    acceptButton.click();

    expect(handleRequestApproval).toHaveBeenCalledTimes(1);
  });
});
