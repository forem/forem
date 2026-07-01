import { isModerationPage } from '@utilities/moderation';

/** This initializes the mod actions button on the article show page (app/views/articles/show.html.erb). */
export function initializeActionsPanel(user, path = '') {
  function getOrCreateModActionsMenu() {
    let modActionsMenu = document.getElementsByClassName('mod-actions-menu')[0];

    if (!modActionsMenu) {
      modActionsMenu = document.createElement('div');
      modActionsMenu.className = 'mod-actions-menu print-hidden';
      document.body.appendChild(modActionsMenu);
    }

    return modActionsMenu;
  }

  function toggleModActionsMenu(event) {
    const targetButton =
      event?.currentTarget || event?.target?.closest('.mod-actions-menu-btn');
    const articlePath = targetButton?.dataset?.articlePath || path;
    const modActionsMenu = getOrCreateModActionsMenu();

    const modContainer = document.getElementById('mod-container');

    if (
      !modContainer ||
      modContainer.getAttribute('src') !== `${articlePath}/actions_panel`
    ) {
      modActionsMenu.innerHTML = `
        <iframe id="mod-container" src="${articlePath}/actions_panel" title="Moderation panel actions">
        </iframe>
      `;
    }

    modActionsMenu.classList.toggle('showing');

    // showing close icon in the mod panel if it is opened by clicking the button
    const panelDocument = document.getElementById('mod-container')?.contentDocument;

    if (panelDocument) {
      const closePanel = panelDocument.getElementsByClassName(
        'close-actions-panel',
      )[0];

      closePanel && closePanel.classList.remove('hidden');
    }
  }

  function bindModActionsMenuButtons() {
    if (isModerationPage()) {
      return;
    }

    document.addEventListener('click', (event) => {
      const button = event.target.closest('.mod-actions-menu-btn');
      if (!button) {
        return;
      }

      event.preventDefault();
      toggleModActionsMenu({ currentTarget: button });
    });
  }

  bindModActionsMenuButtons();
}
