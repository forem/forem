import { initializeActionsPanel } from '../initializeActionsPanelToggle';

describe('toggling the actions panel', () => {
  describe('when the page is the article show page', () => {
    document.body.innerHTML = `
      <div class="mod-actions-menu"></div>
      <div id="mod-actions-menu-btn-area"></div>
    `;
    const path = '/fakeuser/fake-article-slug-1d3a';

    test('it should render the mod actions menu button', () => {
      initializeActionsPanel(path);
      expect(
        document.querySelector(
          `iframe#mod-container[src="${path}/actions_panel"]`,
        ),
      ).toBeDefined();
      expect(
        document.getElementsByClassName('mod-actions-menu-btn')[0],
      ).not.toBeNull();
      expect(
        document.getElementsByClassName('actions-menu-svg')[0],
      ).not.toBeNull();
    });

    test('it should have a click listener that toggles the appropriate classes', () => {
      initializeActionsPanel(path);

      const modContainer = document.getElementById('mod-container');
      modContainer.contentWindow.document.write(
        `<html><body><button class="close-actions-panel hidden"></body></html>`,
      );

      const modActionsMenu = document.getElementsByClassName(
        'mod-actions-menu',
      )[0];
      const modActionsMenuBtn = document.getElementsByClassName(
        'mod-actions-menu-btn',
      )[0];

      modActionsMenuBtn.click();

      expect(modActionsMenu.classList.contains('showing')).toBeTruthy();
      expect(modActionsMenuBtn.classList.contains('hidden')).toBeTruthy();

      const panelDocument = modContainer.contentDocument;

      const closeButton = panelDocument.getElementsByClassName(
        'close-actions-panel',
      )[0];
      expect(closeButton.classList.contains('hidden')).toBeFalsy();
    });
  });
});
