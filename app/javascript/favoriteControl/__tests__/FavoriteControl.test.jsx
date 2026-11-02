import { h } from 'preact';
import { render, fireEvent, waitFor, screen } from '@testing-library/preact';
import { userEvent } from '@testing-library/user-event';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { FavoriteControl } from '../FavoriteControl';
import { makeFavorite } from '../favoriteService';

jest.mock('../favoriteService', () => ({
  makeFavorite: jest.fn(() => Promise.resolve({ ok: true })),
}));

const CURRENT_USER_ID = 11;
const user = {
  id: CURRENT_USER_ID,
  favorite_allowance: 5,
};

const defaultProps = {
  currentUser: user,
  variant: 'article',
  favoritableType: 'Article',
  favoritableId: '3',
  favoritableUserId: '999',
  favorited: 'false',
  favoritedByUserId: '',
  labelFavorite: 'Pick as gem',
  labelFavorited: 'Picked as gem',
  labelFavoritedByYou: 'Picked as gem by you',
};

const renderControl = (overrides = {}) =>
  render(<FavoriteControl {...defaultProps} {...overrides} />);

const clickGem = () => fireEvent.click(screen.getByLabelText('Pick as gem'));
const confirmGem = () =>
  fireEvent.click(screen.getByRole('button', { name: 'Give Gem' }));
const cancelButton = () => screen.getByRole('button', { name: 'Cancel' });

beforeEach(() => {
  makeFavorite.mockClear();
  makeFavorite.mockResolvedValue({ ok: true });
  window.top.addSnackbarItem = jest.fn();
});

afterEach(() => {
  delete window.top.addSnackbarItem;
});

describe('<FavoriteControl />', () => {
  describe('visibility gating on unfavorited content', () => {
    it('renders for a user with favorites to spend', () => {
      const { getByRole } = renderControl();

      expect(getByRole('button')).toBeInTheDocument();
    });

    it('renders nothing when a non-leader has no favorites to spend', () => {
      const { container } = renderControl({
        currentUser: { id: CURRENT_USER_ID, favorite_allowance: 0, community_leader: false },
      });

      expect(container).toBeEmptyDOMElement();
    });

    it('renders the button for a community leader even when their allowance is 0', () => {
      const { getByRole } = renderControl({
        currentUser: { id: CURRENT_USER_ID, favorite_allowance: 0, community_leader: true },
      });

      expect(getByRole('button')).toBeInTheDocument();
    });

    it('renders nothing when not logged in', () => {
      const { container } = renderControl({ currentUser: null });

      expect(container).toBeEmptyDOMElement();
    });

    it('renders nothing for the content author', () => {
      const { container } = renderControl({
        favoritableUserId: String(CURRENT_USER_ID),
        currentUser: { id: CURRENT_USER_ID, favorite_allowance: 2 },
      });

      expect(container).toBeEmptyDOMElement();
    });
  });

  describe('actionable state', () => {
    it('renders a button labelled for favoriting', () => {
      const { getByLabelText, getByTestId } = renderControl();
      const button = getByLabelText('Pick as gem');

      expect(button.tagName).toBe('BUTTON');
      expect(getByTestId('tooltip')).toHaveTextContent('Pick as gem');
    });

    it('has no a11y violations', async () => {
      const { container } = renderControl();

      expect(await axe(container)).toHaveNoViolations();
    });
  });

  describe('favoriting', () => {
    it('POSTs the favorite, switches to favorited state, and displays the confirmation modal', async () => {
      makeFavorite.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, remaining_allowance: 4 }),
      });
      const { getByLabelText, findByLabelText, findByText, getByText, queryByText } = renderControl();

      clickGem();
      confirmGem();

      expect(makeFavorite).toHaveBeenCalledWith({
        favoritableId: '3',
        favoritableType: 'Article',
      });

      const indicator = await findByLabelText('Picked as gem by you');
      expect(indicator.tagName).toBe('SPAN');

      expect(await findByText('Gem Picked!')).toBeInTheDocument();
      expect(getByText("You've picked this as a community gem!")).toBeInTheDocument();
      expect(getByText('You have 4 more gems left to give out today.')).toBeInTheDocument();

      fireEvent.click(getByText('Got it'));
      expect(queryByText('Gem Picked!')).toBeNull();
    });

    it('shows singular remaining allowance when 1 gem left', async () => {
      makeFavorite.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, remaining_allowance: 1 }),
      });
      const { getByLabelText, findByText } = renderControl();

      clickGem();
      confirmGem();

      expect(await findByText('You have 1 more gem left to give out today.')).toBeInTheDocument();
    });

    it('shows zero remaining allowance when 0 gems left', async () => {
      makeFavorite.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, remaining_allowance: 0 }),
      });
      const { getByLabelText, findByText } = renderControl();

      clickGem();
      confirmGem();

      expect(await findByText('You have no more gems left to give out today.')).toBeInTheDocument();
    });

    it('shows an unlimited allowance when the API reports a null remaining allowance', async () => {
      makeFavorite.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, remaining_allowance: null }),
      });
      const { getByLabelText, findByText } = renderControl({
        currentUser: {
          id: CURRENT_USER_ID,
          favorite_allowance: null,
          community_leader: true,
        },
      });

      clickGem();
      confirmGem();

      expect(
        await findByText('You have unlimited gems to give out.'),
      ).toBeInTheDocument();
    });

    it('lets an unmetered curator favorite instead of showing the out of gems modal', async () => {
      makeFavorite.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, remaining_allowance: null }),
      });
      const { getByLabelText, findByLabelText, queryByText } = renderControl({
        currentUser: {
          id: CURRENT_USER_ID,
          favorite_allowance: null,
          community_leader: true,
        },
      });

      clickGem();
      confirmGem();

      expect(makeFavorite).toHaveBeenCalled();
      expect(await findByLabelText('Picked as gem by you')).toBeInTheDocument();
      expect(queryByText('Out of Gems')).toBeNull();
    });

    it('shows the out of gems modal when a community leader with 0 gems attempts to favorite', async () => {
      const { getByLabelText, getByText, findByText, queryByText } = renderControl({
        currentUser: { id: CURRENT_USER_ID, favorite_allowance: 0, community_leader: true },
      });

      fireEvent.click(getByLabelText('Pick as gem'));

      expect(makeFavorite).not.toHaveBeenCalled();
      expect(queryByText('Give Gem')).toBeNull();
      expect(await findByText('Out of Gems')).toBeInTheDocument();
      expect(
        getByText('You have no more gems left to give out today. Your allowance will refresh soon!'),
      ).toBeInTheDocument();

      fireEvent.click(getByText('Got it'));
      expect(queryByText('Out of Gems')).toBeNull();
    });

    it('shows the out of gems modal when the API returns no_allowance error code', async () => {
      makeFavorite.mockResolvedValue({
        ok: false,
        json: async () => ({
          error: 'You have no more gems.',
          code: 'no_allowance',
        }),
      });
      const { getByLabelText, findByText } = renderControl();

      clickGem();
      confirmGem();

      expect(await findByText('Out of Gems')).toBeInTheDocument();
    });

    it('shows an error message on failure', async () => {
      makeFavorite.mockResolvedValue({
        ok: false,
        json: async () => ({
          error: 'Unable to pick this as a gem.',
          code: 'cannot_favorite',
        }),
      });
      const { getByLabelText } = renderControl();

      clickGem();
      confirmGem();

      await waitFor(() =>
        expect(window.top.addSnackbarItem).toHaveBeenCalledWith({
          message: 'Unable to pick this as a gem.',
          addCloseButton: true,
        }),
      );
    });

    it('reconciles to favorited state when already favorited', async () => {
      makeFavorite.mockResolvedValue({
        ok: false,
        json: async () => ({
          error: 'This has already been picked as a gem.',
          code: 'already_favorited',
        }),
      });
      const { getByLabelText, findByLabelText } = renderControl();

      clickGem();
      confirmGem();

      const indicator = await findByLabelText('Picked as gem');
      expect(indicator.tagName).toBe('SPAN');
      expect(window.top.addSnackbarItem).toHaveBeenCalledWith({
        message: 'This has already been picked as a gem.',
        addCloseButton: true,
      });
    });
  });

  describe('already-favorited state', () => {
    it('renders an indicator when favorited by the viewer', () => {
      const { getByLabelText } = renderControl({
        favorited: 'true',
        favoritedByUserId: String(CURRENT_USER_ID),
      });

      const indicator = getByLabelText('Picked as gem by you');
      expect(indicator.tagName).toBe('SPAN');
    });

    it('has no a11y violations in the favorited state', async () => {
      const { container } = renderControl({
        favorited: 'true',
        favoritedByUserId: String(CURRENT_USER_ID),
      });

      expect(await axe(container)).toHaveNoViolations();
    });

    it('renders an indicator when favorited by someone else', () => {
      const { getByLabelText } = renderControl({
        favorited: 'true',
        favoritedByUserId: '7',
      });

      const indicator = getByLabelText('Picked as gem');
      expect(indicator.tagName).toBe('SPAN');
    });

    it('renders an indicator for a signed-out visitor', () => {
      const { getByLabelText } = renderControl({
        currentUser: null,
        favorited: 'true',
        favoritedByUserId: '7',
      });

      expect(getByLabelText('Picked as gem').tagName).toBe('SPAN');
    });

    it('does not tell a signed-out visitor they favorited it', () => {
      const { getByLabelText, queryByLabelText } = renderControl({
        currentUser: null,
        favorited: 'true',
        favoritedByUserId: '',
      });

      expect(queryByLabelText('Picked as gem by you')).toBeNull();
      expect(getByLabelText('Picked as gem').tagName).toBe('SPAN');
    });
  });

  describe('confirmation dialog', () => {
    const commentProps = {
      variant: 'comment',
      favoritableType: 'Comment',
      favoritableId: '8',
    };

    describe.each([
      [
        'post',
        {},
        'Give this post a Gem?',
        'Are you sure you want to give this post a Gem?',
      ],
      [
        'post (dropdown variant)',
        { variant: 'dropdown' },
        'Give this post a Gem?',
        'Are you sure you want to give this post a Gem?',
      ],
      [
        'comment',
        commentProps,
        'Give this comment a Gem?',
        'Are you sure you want to give this comment a Gem?',
      ],
    ])('for a %s', (_name, overrides, title, body) => {
      it('opens a confirmation dialog without awarding the gem', () => {
        renderControl(overrides);

        expect(screen.queryByRole('dialog')).toBeNull();

        clickGem();

        const dialog = screen.getByRole('dialog', { name: title });
        expect(dialog).toHaveAttribute('aria-modal', 'true');
        expect(dialog).toHaveAccessibleDescription(body);
        expect(
          screen.getByRole('button', { name: 'Give Gem' }),
        ).toBeInTheDocument();
        expect(cancelButton()).toBeInTheDocument();
        expect(makeFavorite).not.toHaveBeenCalled();
      });

      it('leaves the gem state untouched while the dialog is open', () => {
        renderControl(overrides);

        clickGem();

        // Still unfavorited: the trigger is there and no result UI appeared.
        expect(screen.getByLabelText('Pick as gem')).toBeInTheDocument();
        expect(screen.queryByLabelText('Picked as gem by you')).toBeNull();
        expect(screen.queryByText('Gem Picked!')).toBeNull();
        expect(screen.queryByText(/more gems? left to give out/)).toBeNull();
        expect(makeFavorite).not.toHaveBeenCalled();
      });

      it('closes on Cancel without sending a request', async () => {
        renderControl(overrides);
        clickGem();

        fireEvent.click(cancelButton());

        expect(screen.queryByRole('dialog')).toBeNull();
        expect(screen.getByLabelText('Pick as gem')).toBeInTheDocument();
        expect(screen.queryByLabelText('Picked as gem by you')).toBeNull();
        expect(makeFavorite).not.toHaveBeenCalled();
      });

      it('closes on the header close button without sending a request', () => {
        renderControl(overrides);
        clickGem();

        fireEvent.click(screen.getByLabelText('Close', { selector: 'button' }));

        expect(screen.queryByRole('dialog')).toBeNull();
        expect(makeFavorite).not.toHaveBeenCalled();
      });

      it('closes on a backdrop click without sending a request', () => {
        renderControl(overrides);
        clickGem();

        fireEvent.click(screen.getByTestId('modal-overlay'));

        expect(screen.queryByRole('dialog')).toBeNull();
        expect(makeFavorite).not.toHaveBeenCalled();
      });

      it('closes on Escape without sending a request', async () => {
        const user = userEvent.setup();
        renderControl(overrides);
        clickGem();

        await user.keyboard('{Escape}');

        expect(screen.queryByRole('dialog')).toBeNull();
        expect(makeFavorite).not.toHaveBeenCalled();
      });

      it('returns focus to the gem button after dismissal', async () => {
        renderControl(overrides);
        const trigger = screen.getByLabelText('Pick as gem');
        trigger.focus();
        clickGem();

        fireEvent.click(cancelButton());

        await waitFor(() => expect(trigger).toHaveFocus());
      });

      it('sends exactly one award request after confirming, then shows the success modal', async () => {
        makeFavorite.mockResolvedValue({
          ok: true,
          json: async () => ({ success: true, remaining_allowance: 4 }),
        });
        renderControl(overrides);
        clickGem();

        confirmGem();

        expect(makeFavorite).toHaveBeenCalledTimes(1);
        expect(makeFavorite).toHaveBeenCalledWith({
          favoritableId: overrides.favoritableId || '3',
          favoritableType: overrides.favoritableType || 'Article',
        });
        expect(await screen.findByText('Gem Picked!')).toBeInTheDocument();
        expect(screen.queryByRole('dialog', { name: title })).toBeNull();
        expect(
          screen.getByText('You have 4 more gems left to give out today.'),
        ).toBeInTheDocument();
      });
    });

    it('uses the translated copy passed in through props', () => {
      renderControl({
        confirmTitle: 'Titre',
        confirmBody: 'Corps du message',
        confirmSubmit: 'Valider',
        confirmCancel: 'Annuler',
      });

      clickGem();

      const dialog = screen.getByRole('dialog', { name: 'Titre' });
      expect(dialog).toHaveAccessibleDescription('Corps du message');
      expect(
        screen.getByRole('button', { name: 'Valider' }),
      ).toBeInTheDocument();
      expect(
        screen.getByRole('button', { name: 'Annuler' }),
      ).toBeInTheDocument();
    });

    it('prevents duplicate submissions from rapid repeated confirm clicks', async () => {
      let resolveRequest;
      makeFavorite.mockReturnValue(
        new Promise((resolve) => {
          resolveRequest = resolve;
        }),
      );
      renderControl();
      clickGem();
      const confirm = screen.getByRole('button', { name: 'Give Gem' });

      // Native clicks dispatched in the same task: no re-render (and so no
      // disabled button) can happen between them, only the in-flight guard.
      confirm.click();
      confirm.click();
      confirm.click();

      expect(makeFavorite).toHaveBeenCalledTimes(1);

      resolveRequest({
        ok: true,
        json: async () => ({ remaining_allowance: 4 }),
      });
      expect(await screen.findByText('Gem Picked!')).toBeInTheDocument();
      expect(makeFavorite).toHaveBeenCalledTimes(1);
    });

    it('disables both actions and ignores dismissal while the request is in flight', async () => {
      const user = userEvent.setup();
      let resolveRequest;
      makeFavorite.mockReturnValue(
        new Promise((resolve) => {
          resolveRequest = resolve;
        }),
      );
      renderControl();
      clickGem();

      confirmGem();

      await waitFor(() =>
        expect(screen.getByRole('button', { name: 'Give Gem' })).toBeDisabled(),
      );
      expect(cancelButton()).toBeDisabled();

      // Neither Escape nor the backdrop may hide the dialog mid-request.
      await user.keyboard('{Escape}');
      fireEvent.click(screen.getByTestId('modal-overlay'));
      expect(
        screen.getByRole('dialog', { name: 'Give this post a Gem?' }),
      ).toBeInTheDocument();
      expect(makeFavorite).toHaveBeenCalledTimes(1);

      resolveRequest({
        ok: true,
        json: async () => ({ remaining_allowance: 4 }),
      });
      expect(await screen.findByText('Gem Picked!')).toBeInTheDocument();
      expect(
        screen.queryByRole('dialog', { name: 'Give this post a Gem?' }),
      ).toBeNull();
    });

    it('keeps focus inside the dialog after a backdrop click while the request is in flight', async () => {
      const user = userEvent.setup();
      let resolveRequest;
      makeFavorite.mockReturnValue(
        new Promise((resolve) => {
          resolveRequest = resolve;
        }),
      );
      renderControl();
      clickGem();
      confirmGem();
      await waitFor(() =>
        expect(screen.getByRole('button', { name: 'Give Gem' })).toBeDisabled(),
      );

      // A real pointer click (mousedown + click), unlike fireEvent.click, is
      // what makes the focus trap react to a click outside of the dialog.
      await user.click(screen.getByTestId('modal-overlay'));

      const dialog = screen.getByRole('dialog', {
        name: 'Give this post a Gem?',
      });
      expect(dialog).toBeInTheDocument();

      // Both actions are disabled, so only the close button can take focus.
      // Focus must stay in the dialog however many times Tab is pressed.
      for (let i = 0; i < 3; i += 1) {
        await user.tab();
        expect(dialog).toContainElement(document.activeElement);
      }

      resolveRequest({
        ok: true,
        json: async () => ({ remaining_allowance: 4 }),
      });
      expect(await screen.findByText('Gem Picked!')).toBeInTheDocument();
    });

    it('still closes on a backdrop click before the request is sent', async () => {
      const user = userEvent.setup();
      renderControl();
      clickGem();

      await user.click(screen.getByTestId('modal-overlay'));

      expect(screen.queryByRole('dialog')).toBeNull();
      expect(makeFavorite).not.toHaveBeenCalled();
    });

    it('closes the dialog and shows the existing error message when the award fails', async () => {
      makeFavorite.mockResolvedValue({
        ok: false,
        json: async () => ({
          error: 'Unable to pick this as a gem.',
          code: 'cannot_favorite',
        }),
      });
      renderControl();
      clickGem();

      confirmGem();

      await waitFor(() =>
        expect(window.top.addSnackbarItem).toHaveBeenCalledWith({
          message: 'Unable to pick this as a gem.',
          addCloseButton: true,
        }),
      );
      expect(screen.queryByRole('dialog')).toBeNull();
      // Nothing was awarded, so the gem can still be given afterwards.
      const trigger = screen.getByLabelText('Pick as gem');
      expect(trigger).toBeEnabled();
      clickGem();
      expect(
        screen.getByRole('dialog', { name: 'Give this post a Gem?' }),
      ).toBeInTheDocument();
    });

    it('swaps the dialog for the out of gems modal when the API reports no allowance', async () => {
      makeFavorite.mockResolvedValue({
        ok: false,
        json: async () => ({
          error: 'You have no more gems.',
          code: 'no_allowance',
        }),
      });
      renderControl();
      clickGem();

      confirmGem();

      expect(await screen.findByText('Out of Gems')).toBeInTheDocument();
      expect(screen.queryByRole('button', { name: 'Give Gem' })).toBeNull();
    });

    it('reconciles to the favorited state when it was already picked', async () => {
      makeFavorite.mockResolvedValue({
        ok: false,
        json: async () => ({
          error: 'This has already been picked as a gem.',
          code: 'already_favorited',
        }),
      });
      renderControl(commentProps);
      clickGem();

      confirmGem();

      expect(await screen.findByLabelText('Picked as gem')).toBeInTheDocument();
      expect(screen.queryByRole('dialog')).toBeNull();
    });

    it('can be completed with the keyboard alone', async () => {
      const user = userEvent.setup();
      makeFavorite.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, remaining_allowance: 4 }),
      });
      renderControl();
      screen.getByLabelText('Pick as gem').focus();

      await user.keyboard('{Enter}');
      expect(
        screen.getByRole('dialog', { name: 'Give this post a Gem?' }),
      ).toBeInTheDocument();
      expect(makeFavorite).not.toHaveBeenCalled();

      // The trap starts on the header close button; focus then moves through
      // Give Gem and Cancel and wraps back around.
      await waitFor(() =>
        expect(
          screen.getByLabelText('Close', { selector: 'button' }),
        ).toHaveFocus(),
      );
      await user.tab();
      expect(screen.getByRole('button', { name: 'Give Gem' })).toHaveFocus();
      await user.tab();
      expect(cancelButton()).toHaveFocus();
      await user.tab();
      expect(
        screen.getByLabelText('Close', { selector: 'button' }),
      ).toHaveFocus();

      await user.tab();
      await user.keyboard('{Enter}');

      expect(makeFavorite).toHaveBeenCalledTimes(1);
      expect(await screen.findByText('Gem Picked!')).toBeInTheDocument();
    });

    it('can be cancelled with the keyboard alone', async () => {
      const user = userEvent.setup();
      renderControl();
      const trigger = screen.getByLabelText('Pick as gem');
      trigger.focus();

      await user.keyboard('{Enter}');
      await user.tab();
      await user.tab();
      expect(cancelButton()).toHaveFocus();
      await user.keyboard('{Enter}');

      expect(screen.queryByRole('dialog')).toBeNull();
      expect(makeFavorite).not.toHaveBeenCalled();
      await waitFor(() => expect(trigger).toHaveFocus());
    });

    it('has no a11y violations while open', async () => {
      const { container } = renderControl(commentProps);
      clickGem();

      expect(await axe(container)).toHaveNoViolations();
    });

    describe('existing eligibility rules', () => {
      it('shows the out of gems modal instead of the dialog for a leader with no allowance', async () => {
        renderControl({
          currentUser: {
            id: CURRENT_USER_ID,
            favorite_allowance: 0,
            community_leader: true,
          },
        });

        clickGem();

        expect(await screen.findByText('Out of Gems')).toBeInTheDocument();
        expect(screen.queryByRole('button', { name: 'Give Gem' })).toBeNull();
        expect(makeFavorite).not.toHaveBeenCalled();
      });

      it('still renders no control, and so no dialog, for the author', () => {
        const { container } = renderControl({
          favoritableUserId: String(CURRENT_USER_ID),
        });

        expect(container).toBeEmptyDOMElement();
      });

      it('still renders no control, and so no dialog, for a user without gems to give', () => {
        const { container } = renderControl({
          currentUser: {
            id: CURRENT_USER_ID,
            favorite_allowance: 0,
            community_leader: false,
          },
        });

        expect(container).toBeEmptyDOMElement();
      });

      it('lets an unmetered curator confirm and award', async () => {
        makeFavorite.mockResolvedValue({
          ok: true,
          json: async () => ({ success: true, remaining_allowance: null }),
        });
        renderControl({
          currentUser: {
            id: CURRENT_USER_ID,
            favorite_allowance: null,
            community_leader: true,
          },
        });

        clickGem();
        expect(makeFavorite).not.toHaveBeenCalled();
        confirmGem();

        expect(makeFavorite).toHaveBeenCalledTimes(1);
        expect(
          await screen.findByText('You have unlimited gems to give out.'),
        ).toBeInTheDocument();
      });
    });
  });

  describe('dropdown variant', () => {
    it('renders an actionable dropdown button with text and icon', () => {
      const { getByRole, getByText } = renderControl({ variant: 'dropdown' });

      const button = getByRole('button');
      expect(button).toHaveClass('crayons-link');
      expect(getByText('Pick as gem')).toHaveClass('fw-bold');
    });

    it('renders a favorited indicator in the dropdown', () => {
      const { getByLabelText, getByText } = renderControl({
        variant: 'dropdown',
        favorited: 'true',
        favoritedByUserId: String(CURRENT_USER_ID),
      });

      const indicator = getByLabelText('Picked as gem by you');
      expect(indicator.tagName).toBe('SPAN');
      expect(getByText('Picked as gem by you')).toHaveClass('fw-bold');
    });
  });
});
