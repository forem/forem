// TODO: Once this is merged, PR up the removal of this and in other tests and move it to testSetup.js
import '@testing-library/jest-dom';
import {
  getByTestId,
  getByLabelText,
  getByText,
  fireEvent,
  waitFor,
} from '@testing-library/dom';
import {
  getInstantClick,
  initializeMobileMenu,
  setCurrentPageIconLink,
  initializeMemberMenu,
} from '../utilities';

// TODO: ★★★ These tests should be promoted to E2E tests once we have that in place. ★★★
describe('top navigation utilitities', () => {
  beforeEach(() => {
    // Recreating the body element completely so as to remove any CSS classes
    // that were added to it.
    document.body = document.createElement('body');
  });

  describe('getInstantClick', () => {
    it('should fail if not found in the alloted time.', async () => {
      await expect(getInstantClick(50)).rejects.toEqual(
        new Error('Unable to resolve InstantClick'),
      );
    });

    it('should resolve InstantClick.', async () => {
      global.InstantClick = {};

      expect(await getInstantClick(50)).toEqual(InstantClick);

      delete global.InstantClick;
    });
  });

  describe('initializeMobileMenu', () => {
    it('should open the hamburger menu', () => {
      document.body.innerHTML = `
    <button aria-label="nav-button-left" class="crayons-btn crayons-btn--ghost crayons-btn--icon-rounded js-hamburger-trigger inline-block m:hidden mx-2">
      <svg><title>Navigation menu</title></svg>
    </button>
      `;

      const navButton = getByLabelText(document.body, 'nav-button-left');

      initializeMobileMenu([navButton], []);

      expect(document.body.dataset.leftNavState).toBeUndefined();
      navButton.click();
      expect(document.body.dataset.leftNavState).toEqual('open');
    });

    it('should close the hamburger menu', () => {
      document.body.innerHTML = `
    <button aria-label="nav-button-left" class="crayons-btn crayons-btn--ghost crayons-btn--icon-rounded js-hamburger-trigger inline-block m:hidden mx-2">
      <svg><title>Navigation menu</title></svg>
    </button>
      `;
      const navButton = getByLabelText(document.body, 'nav-button-left');

      initializeMobileMenu([navButton], []);

      expect(document.body.dataset.leftNavState).toBeUndefined();
      navButton.click();
      expect(document.body.dataset.leftNavState).toEqual('open');

      navButton.click();
      expect(document.body.dataset.leftNavState).toEqual('closed');
    });

    it('should open the more menu', () => {
      document.body.innerHTML = `
      <a href="javascript:void(0)" class="crayons-link crayons-link--secondary crayons-link--block crayons-link--block--indented fs-s js-nav-more-trigger">More...</a>
      <div class="hidden js-nav-more spec-nav-more">
        <div class="flex justify-around p-4 mt-4 border-solid border-0 border-t-1 border-base-10">
        </div>
      </div>
      `;

      const navMoreLink = getByText(document.body, 'More...');

      initializeMobileMenu([], [navMoreLink]);

      navMoreLink.click();

      expect(navMoreLink).toHaveClass('hidden');
    });
  });

  describe('setCurrentPageIconLink', () => {
    it('should set the current page icon', () => {
      document.body.innerHTML = `
        <a href="/connect" id="connect-link" class="crayons-header__link crayons-btn crayons-btn--ghost crayons-btn--icon-rounded" aria-label="Connect"></a>
        <a href="/notifications" id="notifications-link" class="crayons-header__link crayons-btn crayons-btn--ghost crayons-btn--icon-rounded" aria-label="Notifications"></a>
    `;

      const connectLink = getByLabelText(document.body, 'Connect');
      const notificationsLink = getByLabelText(document.body, 'Notifications');

      const pageEntries = Object.entries({
        'page-1': connectLink,
        'page-2': notificationsLink,
      });

      const page = 'page-1';

      setCurrentPageIconLink(page, pageEntries);

      expect(connectLink).toHaveClass('crayons-header__link--current');
      expect(notificationsLink).not.toHaveClass(
        'crayons-header__link--current',
      );
    });

    it('should set the current page icon and remove the previous current page icon styling', () => {
      document.body.innerHTML = `
        <a href="/connect" id="connect-link" class="crayons-header__link crayons-btn crayons-btn--ghost crayons-btn--icon-rounded" aria-label="Connect"></a>
        <a href="/notifications" id="notifications-link" class="crayons-header__link crayons-header__link--current crayons-btn crayons-btn--ghost crayons-btn--icon-rounded" aria-label="Notifications"></a>
    `;

      const connectLink = getByLabelText(document.body, 'Connect');
      const notificationsLink = getByLabelText(document.body, 'Notifications');

      const pageEntries = Object.entries({
        'page-1': connectLink,
        'page-2': notificationsLink,
      });

      const page = 'page-1';

      setCurrentPageIconLink(page, pageEntries);

      expect(connectLink).toHaveClass('crayons-header__link--current');
      expect(notificationsLink).not.toHaveClass(
        'crayons-header__link--current',
      );
    });
  });

  describe('initializeMemberMenu', () => {
    const initialMenuHTML = `
      <div class="crayons-header__menu" id="crayons-header__menu" data-testid="menu-dropdown">
        <button type="button" class="crayons-header__menu__trigger" id="member-menu-button" aria-expanded="false" aria-label="Navigation menu">
          <span class="crayons-avatar crayons-avatar--l"><img class="crayons-avatar__image" alt="" id="nav-profile-image" src=""></span>
        </button>
        <div class="crayons-dropdown left-2 right-2 s:right-4 s:left-auto p-0 crayons-header__menu__dropdown inline-block">
          <ul class="p-0" id="crayons-header__menu__dropdown__list">
            <li id="user-profile-link-placeholder" class="border-0 border-b-1 border-solid border-base-20 p-1 mb-1">
              <a id="first-nav-link" class="crayons-link crayons-link--block" href="">
              </a>
            </li>
            <li class="px-1 py-1">
              <a href="/signout_confirm" class="crayons-link crayons-link--block" id="last-nav-link">Sign Out</a>
            </li>
          </ul>
        </div>
      </div>
    `;

    it('toggles dropdown menu expanded state', async () => {
      document.body.innerHTML = initialMenuHTML;

      const menuNavButton = getByLabelText(document.body, 'Navigation menu');
      const memberMenu = getByTestId(document.body, 'menu-dropdown');

      initializeMemberMenu(memberMenu, menuNavButton);

      await waitFor(() =>
        expect(menuNavButton.getAttribute('aria-expanded')).toEqual('false'),
      );
      expect(menuNavButton.getAttribute('aria-expanded')).toEqual('false');
      expect(memberMenu).not.toHaveClass('showing');

      fireEvent.click(menuNavButton);

      expect(menuNavButton.getAttribute('aria-expanded')).toEqual('true');
      expect(memberMenu).toHaveClass('showing');

      fireEvent.click(menuNavButton);

      expect(menuNavButton.getAttribute('aria-expanded')).toEqual('false');
      expect(memberMenu).not.toHaveClass('showing');
    });

    it('closes menu on Escape key', async () => {
      document.body.innerHTML = initialMenuHTML;

      const menuNavButton = getByLabelText(document.body, 'Navigation menu');
      const memberMenu = getByTestId(document.body, 'menu-dropdown');

      initializeMemberMenu(memberMenu, menuNavButton);

      await waitFor(() =>
        expect(menuNavButton.getAttribute('aria-expanded')).toEqual('false'),
      );

      fireEvent.click(menuNavButton);

      expect(menuNavButton.getAttribute('aria-expanded')).toEqual('true');
      expect(memberMenu).toHaveClass('showing');

      fireEvent.keyUp(memberMenu, { key: 'Escape' });

      await waitFor(() =>
        expect(menuNavButton.getAttribute('aria-expanded')).toEqual('false'),
      );

      expect(memberMenu).not.toHaveClass('showing');
    });

    it('closes the menu on click outside', async () => {
      document.body.innerHTML = `
        <div data-testid="container">
          ${initialMenuHTML}
        </div>
      `;

      const menuNavButton = getByLabelText(document.body, 'Navigation menu');
      const memberMenu = getByTestId(document.body, 'menu-dropdown');

      initializeMemberMenu(memberMenu, menuNavButton);

      await waitFor(() =>
        expect(menuNavButton.getAttribute('aria-expanded')).toEqual('false'),
      );

      fireEvent.click(menuNavButton);

      expect(menuNavButton.getAttribute('aria-expanded')).toEqual('true');
      expect(memberMenu).toHaveClass('showing');

      // Click on a link in the menu to close load a page and close the menu.
      memberMenu.querySelector('a').click();

      await waitFor(() =>
        expect(menuNavButton.getAttribute('aria-expanded')).toEqual('false'),
      );

      expect(memberMenu).not.toHaveClass('showing');
    });
  });
});
