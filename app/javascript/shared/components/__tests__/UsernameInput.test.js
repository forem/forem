import { h } from 'preact';
import { render } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';

import '@testing-library/jest-dom';

import { UsernameInput } from '../UsernameInput';

function fakeUsers() {
  return [
    { name: 'Alice', username: 'alice', id: 1 },
    { name: 'Bob', username: 'bob', id: 2 },
    { name: 'Charlie', username: 'charlie', id: 3 },
    { name: 'Almost Alice', username: 'almostalice', id: 4 },
  ];
}

describe('<UsernameInput />', () => {
  it('renders the default component', () => {
    const { container } = render(
      <UsernameInput
        labelText="Example label"
        fetchSuggestions={() => {}}
        handleSelectionsChanged={() => {}}
      />,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('calls handleSelectionsChanged with user IDs', async () => {
    const fakeHandler = jest.fn();

    const { getByLabelText, queryByRole } = render(
      <UsernameInput
        labelText="Enter username"
        fetchSuggestions={fakeUsers}
        handleSelectionsChanged={fakeHandler}
      />,
    );

    const input = getByLabelText('Enter username');
    input.focus();
    await userEvent.type(input, 'Bob,');
    await userEvent.type(input, 'Charlie,');

    expect(queryByRole('button', { name: 'Edit example' })).toBeNull();
    expect(fakeHandler).toHaveBeenCalledWith('2, 3');
  });
});
