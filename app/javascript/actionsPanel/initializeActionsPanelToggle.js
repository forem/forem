/** This initializes the mod actions button on the article show page (app/views/articles/show.html.erb). */
export default function initializeActionsPanel(user, path) {
  const modActionsMenuHTML = `<iframe id="mod-container" src=${path}/actions_panel></iframe>`;
  const modActionsMenuIconHTML = `<div class="mod-actions-menu-btn crayons-btn crayons-btn--icon-rounded crayons-btn--s">
  <svg xmlns="http://www.w3.org/2000/svg" width="54px" height="54px" viewBox="-8 -8 40 40" class="crayons-icon actions-menu-svg" role="img" aria-labelledby=""><title id="">Moderation</title><path d="M3.783 2.826L12 1l8.217 1.826a1 1 0 01.783.976v9.987a6 6 0 01-2.672 4.992L12 23l-6.328-4.219A6 6 0 013 13.79V3.802a1 1 0 01.783-.976zM5 4.604v9.185a4 4 0 001.781 3.328L12 20.597l5.219-3.48A4 4 0 0019 13.79V4.604L12 3.05 5 4.604zM13 10h3l-5 7v-5H8l5-7v5z"></path></svg>
</div>
`;

  function toggleModActionsMenu() {
    document.querySelector('.mod-actions-menu').classList.toggle('showing');
    document.querySelector('.mod-actions-menu-btn').classList.toggle('hidden');
  }

  document.querySelector('.mod-actions-menu').innerHTML = modActionsMenuHTML;
  // eslint-disable-next-line no-restricted-globals
  if (!top.document.location.pathname.endsWith('/mod')) {
    document.getElementById(
      'mod-actions-menu-btn-area',
    ).innerHTML = modActionsMenuIconHTML;
    document
      .querySelector('.mod-actions-menu-btn')
      .addEventListener('click', toggleModActionsMenu);
  }
}
