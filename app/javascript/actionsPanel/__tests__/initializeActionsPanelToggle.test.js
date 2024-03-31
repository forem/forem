import { initializeActionsPanel } from '../initializeActionsPanelToggle';

describe('toggling the actions panel', () => {
  describe('when the page is the article show page', () => {
    document.body.innerHTML = `
      <div class="mod-actions-menu"></div>
      <div id="mod-actions-menu-btn-area">
        <button class="crayons-btn crayons-btn--ghost crayons-btn--icon-rounded mod-actions-menu-btn">
          <svg width="24" height="24" class="crayons-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-labelledby="d6cd43ffbad3fe639e2e95c901ee88c8">
            <title id="d6cd43ffbad3fe639e2e95c901ee88c8">Moderation</title>
            <path d="M3.783 2.826L12 1l8.217 1.826a1 1 0 01.783.976v9.987a6 6 0 01-2.672 4.992L12 23l-6.328-4.219A6 6 0 013 13.79V3.802a1 1 0 01.783-.976zM5 4.604v9.185a4 4 0 001.781 3.328L12 20.597l5.219-3.48A4 4 0 0019 13.79V4.604L12 3.05 5 4.604zM13 10h3l-5 7v-5H8l5-7v5z"/>
          </svg>
        </button>
      </div>
    `;
    const path = '/fakeuser/fake-article-slug-1d3a';

    test('it should have a click listener that toggles the appropriate classes', () => {
      initializeActionsPanel(path);

      const modContainer = document.getElementById('mod-container');
      modContainer.contentWindow.document.write(
        `<html><body><button class="close-actions-panel hidden"></body></html>`,
      );

      const modActionsMenu =
        document.getElementsByClassName('mod-actions-menu')[0];
      const modActionsMenuBtn = document.getElementsByClassName(
        'mod-actions-menu-btn',
      )[0];

      modActionsMenuBtn.click();

      expect(modActionsMenu.classList.contains('showing')).toBeTruthy();

      const panelDocument = modContainer.contentDocument;

      const closeButton = panelDocument.getElementsByClassName(
        'close-actions-panel',
      )[0];
      expect(closeButton.classList.contains('hidden')).toBeFalsy();
    });
  });
});
