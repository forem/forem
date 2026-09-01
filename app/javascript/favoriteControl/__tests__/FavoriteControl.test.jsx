import { h } from 'preact';
import { render, fireEvent, waitFor } from '@testing-library/preact';
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

      fireEvent.click(getByLabelText('Pick as gem'));

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

      fireEvent.click(getByLabelText('Pick as gem'));

      expect(await findByText('You have 1 more gem left to give out today.')).toBeInTheDocument();
    });

    it('shows zero remaining allowance when 0 gems left', async () => {
      makeFavorite.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, remaining_allowance: 0 }),
      });
      const { getByLabelText, findByText } = renderControl();

      fireEvent.click(getByLabelText('Pick as gem'));

      expect(await findByText('You have no more gems left to give out today.')).toBeInTheDocument();
    });

    it('shows the out of gems modal when a community leader with 0 gems attempts to favorite', async () => {
      const { getByLabelText, getByText, findByText, queryByText } = renderControl({
        currentUser: { id: CURRENT_USER_ID, favorite_allowance: 0, community_leader: true },
      });

      fireEvent.click(getByLabelText('Pick as gem'));

      expect(makeFavorite).not.toHaveBeenCalled();
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

      fireEvent.click(getByLabelText('Pick as gem'));

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

      fireEvent.click(getByLabelText('Pick as gem'));

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

      fireEvent.click(getByLabelText('Pick as gem'));

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
