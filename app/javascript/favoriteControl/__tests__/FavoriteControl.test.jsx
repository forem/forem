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
const leader = { id: CURRENT_USER_ID, community_leader: true };

const defaultProps = {
  currentUser: leader,
  variant: 'article',
  favoritableType: 'Article',
  favoritableId: '3',
  favoritableUserId: '999',
  favorited: 'false',
  favoritedByUserId: '',
  labelFavorite: 'Favorite',
  labelFavorited: 'Favorited',
  labelFavoritedByYou: 'Favorited by you',
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
  describe('visibility gating', () => {
    it('renders nothing when the viewer is not a community leader', () => {
      const { container } = renderControl({
        currentUser: { id: CURRENT_USER_ID, community_leader: false },
      });

      expect(container).toBeEmptyDOMElement();
      expect(makeFavorite).not.toHaveBeenCalled();
    });

    it('renders nothing when not logged in', () => {
      const { container } = renderControl({ currentUser: null });

      expect(container).toBeEmptyDOMElement();
    });

    it('renders nothing for the content author', () => {
      const { container } = renderControl({
        favoritableUserId: String(CURRENT_USER_ID),
      });

      expect(container).toBeEmptyDOMElement();
    });
  });

  describe('actionable state', () => {
    it('renders a button labelled for favoriting', () => {
      const { getByLabelText, getByTestId } = renderControl();
      const button = getByLabelText('Favorite');

      expect(button.tagName).toBe('BUTTON');
      expect(getByTestId('tooltip')).toHaveTextContent('Favorite');
    });

    it('has no a11y violations', async () => {
      const { container } = renderControl();

      expect(await axe(container)).toHaveNoViolations();
    });
  });

  describe('favoriting', () => {
    it('POSTs the favorite and switches to favorited state on click', async () => {
      const { getByLabelText, findByLabelText } = renderControl();

      fireEvent.click(getByLabelText('Favorite'));

      expect(makeFavorite).toHaveBeenCalledWith({
        favoritableId: '3',
        favoritableType: 'Article',
      });

      const indicator = await findByLabelText('Favorited by you');
      expect(indicator.tagName).toBe('SPAN');
    });

    it('shows an error message on failure', async () => {
      makeFavorite.mockResolvedValue({
        ok: false,
        json: async () => ({
          error: 'Unable to make this a favorite.',
          code: 'cannot_favorite',
        }),
      });
      const { getByLabelText, queryByLabelText } = renderControl();

      fireEvent.click(getByLabelText('Favorite'));

      await waitFor(() =>
        expect(window.top.addSnackbarItem).toHaveBeenCalledWith({
          message: 'Unable to make this a favorite.',
          addCloseButton: true,
        }),
      );
    });

    it('reconciles to favorited state when already favorited', async () => {
      makeFavorite.mockResolvedValue({
        ok: false,
        json: async () => ({
          error: 'This has already been made a favorite.',
          code: 'already_favorited',
        }),
      });
      const { getByLabelText, findByLabelText } = renderControl();

      fireEvent.click(getByLabelText('Favorite'));

      const indicator = await findByLabelText('Favorited');
      expect(indicator.tagName).toBe('SPAN');
      expect(window.top.addSnackbarItem).toHaveBeenCalledWith({
        message: 'This has already been made a favorite.',
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

      const indicator = getByLabelText('Favorited by you');
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
      const { getByLabelText, container } = renderControl({
        favorited: 'true',
        favoritedByUserId: '7',
      });

      const indicator = getByLabelText('Favorited');
      expect(indicator.tagName).toBe('SPAN');
    });
  });
});
