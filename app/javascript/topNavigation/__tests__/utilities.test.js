// TODO: Once this is merged, PR up the removal of this and in other tests and move it to testSetup.js
import '@testing-library/jest-dom';
import { getByLabelText } from '@testing-library/dom';
import {
  getInstantClick,
  initializeMobileMenu,
  setCurrentPageIconLink,
} from '../utilities';

// TODO: ★★★ These tests should be promoted to E2E tests once we have that in place. ★★★
describe('top navigation utilities', () => {
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
    <button aria-label="nav-button-left" class="c-btn c-btn--icon-alone radius-full js-hamburger-trigger mx-2">
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
    <button aria-label="nav-button-left" class="c-btn c-btn--icon-alone radius-full js-hamburger-trigger mx-2">
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
  });

  describe('setCurrentPageIconLink', () => {
    it('should set the current page icon', () => {
      document.body.innerHTML = `
        <a href="/notifications" id="notifications-link" class="c-link c-link--icon-alone c-link--block radius-full mx-1" aria-current="page" aria-label="Notifications"></a>
    `;

      const notificationsLink = getByLabelText(document.body, 'Notifications');

      const pageEntries = Object.entries({
        'page-1': notificationsLink,
      });

      setCurrentPageIconLink('page-1', pageEntries);

      expect(notificationsLink).toHaveAttribute('aria-current', 'page');
    });
  });
});
