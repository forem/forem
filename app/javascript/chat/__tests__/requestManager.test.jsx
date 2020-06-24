import { h } from 'preact';
import { render, waitForElement } from '@testing-library/preact';
import { axe } from 'jest-axe';
import RequestManager  from '../requestManager';

const data = [
  {
    id: 2,
    channel_name: 'ironman',
  },
];

describe('<RequestManager />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <RequestManager resource={data} handleRequestRejection={jest.fn()} handleRequestApproval={jest.fn()} />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });


  it('should have the proper elements', () => {
    const { getByTestId, debug, getByText } = render(
      <RequestManager resource={data} handleRequestRejection={jest.fn()} handleRequestApproval={jest.fn()} />
    );

    getByText(/Joining Request/i);
    getByText(/Manage request coming to all the channels/i);
    const request = getByTestId('request');
    expect(request.textContent).toContain('Reject');
    expect(request.textContent).toContain('Accept');
  });

  xit('should call the relavant handlers when the buttons are clicked', async ()=> {
    const handleRequestRejection = jest.fn();
    const handleRequestApproval = jest.fn();

    const { getByText } = render(
      <RequestManager resource={data} handleRequestRejection={jest.fn()} handleRequestApproval={jest.fn()} />
    );
    const rejectButton = getByText(/Reject/i);
    const acceptButton = getByText(/Accept/i);

    rejectButton.click();
    await waitForElement(() => expect(handleRequestRejection).toHaveBeenCalledTimes(1))

    acceptButton.click();
    await waitForElement(() => expect(handleRequestApproval).toHaveBeenCalledTimes(1))
  })
});
