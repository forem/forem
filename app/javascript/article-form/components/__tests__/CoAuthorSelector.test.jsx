import { h } from 'preact';
import { render, screen, waitFor } from '@testing-library/preact';
import { userEvent } from '@testing-library/user-event';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import { CoAuthorSelector } from '../CoAuthorSelector';

global.fetch = fetch;

jest.mock('@utilities/locale', () => ({
  locale: (key) =>
    ({
      'core.article_form_co_authors': 'Co-authors',
      'core.article_form_co_authors_description':
        'Add up to 4 co-authors from the selected organization.',
      'core.article_form_co_authors_placeholder': 'Add up to 4...',
    })[key] || key,
}));

jest.mock('@utilities/debounceAction', () => ({
  debounceAction: (fn) => fn,
}));

describe('<CoAuthorSelector />', () => {
  const organizations = [
    {
      id: 1,
      name: 'Forem',
      can_add_co_authors: true,
      fetch_users_url: '/forem/members.json',
    },
    {
      id: 2,
      name: 'Other Org',
      can_add_co_authors: false,
      fetch_users_url: '/other/members.json',
    },
  ];

  beforeEach(() => {
    fetch.resetMocks();
    global.Honeybadger = { notify: jest.fn() };
    window.fetch = fetch;
    fetch.mockResponse(
      JSON.stringify([
        { id: 1, name: 'Alice', username: 'alice' },
        { id: 2, name: 'Bob', username: 'bob' },
      ]),
    );
  });

  it('stays hidden when no eligible organization is selected', () => {
    render(
      <CoAuthorSelector
        authorId={1}
        coAuthorIdsList=""
        organizationId={2}
        organizations={organizations}
        onConfigChange={jest.fn()}
      />,
    );

    expect(screen.queryByText('Co-authors')).not.toBeInTheDocument();
    expect(fetch).not.toHaveBeenCalled();
  });

  it('fetches org members and shows the picker for eligible organizations', async () => {
    render(
      <CoAuthorSelector
        authorId={1}
        coAuthorIdsList="2"
        organizationId={1}
        organizations={organizations}
        onConfigChange={jest.fn()}
      />,
    );

    await waitFor(() => expect(fetch).toHaveBeenCalledWith('/forem/members.json'));
    expect((await screen.findAllByText('Co-authors')).length).toBeGreaterThan(0);
    expect(await screen.findByText('Bob')).toBeInTheDocument();
  });

  it('syncs selected co-authors back into editor state', async () => {
    const onConfigChange = jest.fn();

    render(
      <CoAuthorSelector
        authorId={1}
        coAuthorIdsList=""
        organizationId={1}
        organizations={organizations}
        onConfigChange={onConfigChange}
      />,
    );

    const input = await screen.findByPlaceholderText('Add up to 4...');
    input.focus();
    await userEvent.type(input, 'Bob,');

    await waitFor(() =>
      expect(onConfigChange).toHaveBeenCalledWith(
        expect.objectContaining({
          target: expect.objectContaining({
            name: 'coAuthorIdsList',
            value: '2',
          }),
        }),
      ),
    );
  });
});
