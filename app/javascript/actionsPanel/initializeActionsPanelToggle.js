import { isModerationPage } from '@utilities/moderation';

/** This initializes the mod actions button on the article show page (app/views/articles/show.html.erb). */
export function initializeActionsPanel(user, path) {
  const modActionsMenuHTML = `
    <iframe id="mod-container" src=${path}/actions_panel title="Moderation panel actions">
    </iframe>
  `;

  function toggleModActionsMenu() {
    document
      .getElementById('mod-actions-menu-btn-area')
      .classList.remove('hidden');
    document
      .getElementsByClassName('mod-actions-menu')[0]
      .classList.toggle('showing');

    // showing close icon in the mod panel if it is opened by clicking the button
    const modContainer = document.getElementById('mod-container');
    const panelDocument = modContainer.contentDocument;

    if (panelDocument) {
      const closePanel = panelDocument.getElementsByClassName(
        'close-actions-panel',
      )[0];

      closePanel && closePanel.classList.remove('hidden');
    }
  }

  document.getElementsByClassName('mod-actions-menu')[0].innerHTML =
    modActionsMenuHTML;
  // eslint-disable-next-line no-restricted-globals
  if (!isModerationPage()) {
    // don't show mod button in mod center page

    const modActionsMenuBtns = document.getElementsByClassName(
      'mod-actions-menu-btn',
    );
    modActionsMenuBtns &&
      Array.from(modActionsMenuBtns).forEach((btn) => {
        btn.addEventListener('click', toggleModActionsMenu);
      });
  }
}
