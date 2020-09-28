import initializeActionsPanel from '../initializeActionsPanelToggle';

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
      expect(document.querySelector(`.mod-actions-menu-btn`)).not.toBeNull();
      expect(document.querySelector(`.actions-menu-svg`)).not.toBeNull();
    });

    test('it should have a click listener that toggles the appropriate classes', () => {
      initializeActionsPanel(path);

      const modContainer = document.getElementById('mod-container');
      modContainer.contentWindow.document.write(
        `<html><body><button class="close-actions-panel hidden"></body></html>`,
      );

      const modActionsMenu = document.querySelector('.mod-actions-menu');
      const modActionsMenuBtn = document.querySelector('.mod-actions-menu-btn');

      modActionsMenuBtn.click();

      expect(modActionsMenu.classList.contains('showing')).toBeTruthy();
      expect(modActionsMenuBtn.classList.contains('hidden')).toBeTruthy();

      const panelDocument = modContainer.contentDocument;

      const closeButton = panelDocument.querySelector('.close-actions-panel');
      expect(closeButton.classList.contains('hidden')).toBeFalsy();
    });
  });
});
