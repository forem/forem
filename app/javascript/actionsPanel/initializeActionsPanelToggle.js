import { isModerationPage } from '@utilities/moderation';

/** This initializes the mod actions button on the article show page (app/views/articles/show.html.erb). */
export function initializeActionsPanel(user, path) {
  const modActionsMenuHTML = `
    <iframe id="mod-container" src=${path}/actions_panel title="Moderation panel actions">
    </iframe>
  `;

  const modActionsMenuIconHTML = `
    <button class="crayons-btn crayons-btn--ghost crayons-btn--icon-rounded mod-actions-menu-btn">
      <svg width="24" height="24" class="crayons-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-labelledby="d6cd43ffbad3fe639e2e95c901ee88c8">
        <title id="d6cd43ffbad3fe639e2e95c901ee88c8">Moderation</title>
        <path d="M3.783 2.826L12 1l8.217 1.826a1 1 0 01.783.976v9.987a6 6 0 01-2.672 4.992L12 23l-6.328-4.219A6 6 0 013 13.79V3.802a1 1 0 01.783-.976zM5 4.604v9.185a4 4 0 001.781 3.328L12 20.597l5.219-3.48A4 4 0 0019 13.79V4.604L12 3.05 5 4.604zM13 10h3l-5 7v-5H8l5-7v5z"/>
      </svg>
    </button>
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
  document
    .getElementById('mod-actions-menu-btn-area')
    .classList.remove('hidden');
  // eslint-disable-next-line no-restricted-globals
  if (!isModerationPage()) {
    // don't show mod button in mod center page
    document.getElementById('mod-actions-menu-btn-area').innerHTML =
      modActionsMenuIconHTML;
    document
      .getElementsByClassName('mod-actions-menu-btn')[0]
      .addEventListener('click', toggleModActionsMenu);
  }
}
