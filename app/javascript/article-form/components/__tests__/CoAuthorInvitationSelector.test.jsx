import { h } from 'preact';
import { render, screen, waitFor } from '@testing-library/preact';
import { userEvent } from '@testing-library/user-event';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import { CoAuthorInvitationSelector } from '../CoAuthorInvitationSelector';

global.fetch = fetch;

jest.mock('@utilities/locale', () => ({
  locale: (key, params) =>
    ({
      'core.article_form_co_authors': 'Co-authors',
      'core.article_form_co_author_invitations_description':
        'Invite people who follow you.',
      'core.article_form_co_author_invitations_placeholder':
        'Search your followers...',
      'core.article_form_co_author_invitations_declined': `Declined: ${params?.names}`,
      'core.article_form_co_author_invitation_new': 'Invite on save',
      'core.article_form_co_author_invitation_pending': 'Pending',
      'core.article_form_co_author_invitation_accepted': 'Accepted',
    })[key] || key,
}));

jest.mock('@utilities/debounceAction', () => ({
  debounceAction: (fn) => fn,
}));

const ada = {
  id: 1,
  name: 'Ada Lovelace',
  username: 'ada',
  profile_image_90: '/ada.png',
};
const grace = {
  id: 2,
  name: 'Grace Hopper',
  username: 'grace',
  profile_image_90: '/grace.png',
};
const linus = {
  id: 3,
  name: 'Linus Torvalds',
  username: 'linus',
  profile_image_90: '/linus.png',
};

describe('<CoAuthorInvitationSelector />', () => {
  beforeEach(() => {
    fetch.resetMocks();
    window.fetch = fetch;
    global.Honeybadger = { notify: jest.fn() };
  });

  it('shows the status of each saved invitation', () => {
    render(
      <CoAuthorInvitationSelector
        invitees={[ada, grace]}
        invitations={[
          { id: 10, status: 'pending', user: ada },
          { id: 11, status: 'accepted', user: grace },
        ]}
        maxSelections={4}
        onConfigChange={jest.fn()}
      />,
    );

    expect(screen.getByRole('group', { name: 'ada' })).toHaveTextContent(
      'Ada LovelacePending',
    );
    expect(screen.getByRole('group', { name: 'grace' })).toHaveTextContent(
      'Grace HopperAccepted',
    );
  });

  it('lists people who declined', () => {
    render(
      <CoAuthorInvitationSelector
        invitees={[]}
        invitations={[{ id: 12, status: 'declined', user: linus }]}
        maxSelections={4}
        onConfigChange={jest.fn()}
      />,
    );

    expect(screen.getByText('Declined: Linus Torvalds')).toBeInTheDocument();
  });

  it('searches followers and syncs a new selection into editor state', async () => {
    fetch.mockResponse(JSON.stringify([ada, linus]));
    const onConfigChange = jest.fn();

    render(
      <CoAuthorInvitationSelector
        invitees={[]}
        invitations={[{ id: 12, status: 'declined', user: linus }]}
        maxSelections={4}
        onConfigChange={onConfigChange}
      />,
    );

    const input = screen.getByPlaceholderText('Search your followers...');
    input.focus();
    await userEvent.type(input, 'a');

    await waitFor(() =>
      expect(fetch).toHaveBeenCalledWith(
        '/co_author_invitations/candidates?search=a',
        expect.objectContaining({ credentials: 'same-origin' }),
      ),
    );

    // Linus declined, so he can't be suggested again.
    expect(await screen.findByText('@ada')).toBeInTheDocument();
    expect(screen.queryByText('@linus')).not.toBeInTheDocument();

    await userEvent.click(screen.getByRole('option', { name: /@ada/ }));

    await waitFor(() =>
      expect(onConfigChange).toHaveBeenCalledWith(
        expect.objectContaining({
          target: { name: 'coAuthorInvitees', value: [ada] },
        }),
      ),
    );
  });

  it('labels new selections as invited on save', () => {
    render(
      <CoAuthorInvitationSelector
        invitees={[ada]}
        invitations={[]}
        maxSelections={4}
        onConfigChange={jest.fn()}
      />,
    );

    expect(screen.getByRole('group', { name: 'ada' })).toHaveTextContent(
      'Invite on save',
    );
  });

  it('removes an invitee', async () => {
    const onConfigChange = jest.fn();

    render(
      <CoAuthorInvitationSelector
        invitees={[ada, grace]}
        invitations={[{ id: 10, status: 'pending', user: ada }]}
        maxSelections={4}
        onConfigChange={onConfigChange}
      />,
    );

    await userEvent.click(screen.getByRole('button', { name: 'Remove ada' }));

    expect(onConfigChange).toHaveBeenCalledWith(
      expect.objectContaining({
        target: { name: 'coAuthorInvitees', value: [grace] },
      }),
    );
  });

  it('returns no suggestions when the search fails', async () => {
    fetch.mockResponse('', { status: 500 });

    render(
      <CoAuthorInvitationSelector
        invitees={[]}
        invitations={[]}
        maxSelections={4}
        onConfigChange={jest.fn()}
      />,
    );

    const input = screen.getByPlaceholderText('Search your followers...');
    input.focus();
    await userEvent.type(input, 'a');

    await waitFor(() => expect(fetch).toHaveBeenCalled());
    expect(screen.queryByRole('option')).not.toBeInTheDocument();
  });
});
