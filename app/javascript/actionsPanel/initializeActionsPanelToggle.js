const flagUserModalHTML = `
    <div class="flag-user-modal-subcont hidden">
        <div class="crayons-modal flag-user-modal">
          <div class="flag-user-modal-header">
            <span class="modal-header-text">Flag User</span>
            <span class="modal-header-close-icon"></span>

          </div>
          <div class="flag-user-modal-body">
            <span>
              Thanks for keeping DEV safe. Here is what you can do to flag this user:
            </span>
            <div class="crayons-fields">
              <div class="crayons-field crayons-field--radio">
                <input
                  type="radio"
                  id="vomit-all"
                  name="flag-user"
                  class="crayons-radio"
                  data-reactable-id="<%= @article.user.id %>"
                  data-category="vomit"
                  data-reactable-type="<%= @article.user.class.name %>">
                <label for="vomit-all" class="crayons-field__label">
                  Make all posts by this author less visible
                  <p class="crayons-field__description">
                    This author consistently posts content that violates DEV's code of conduct because it is harassing, offensive or spammy.
                  </p>
                </label>
              </div>
              <a href="/report-abuse?url=<%= request.url %>" class="fs-base abuse-report-link">Report other inappropriate conduct</a>
            </div>
            <div class="buttons-container">
              <a href="#" class="crayons-btn" id="confirm-flag-user-action">Confirm action</a>
              <a href="#" class="crayons-btn" id="cancel-flag-user-action">Cancel</a>
            </div>
          </div>
        </div>
        <div class="crayons-snackbar">
          <div class="crayons-snackbar__item" id="vomit-all-snackbar">
            <div class="crayons-snackbar__body">
              <p>All posts by this author will be less visible.</p>
            </div>
          </div>
          <div class="crayons-snackbar__item" id="abuse-report-snackbar">
            <div class="crayons-snackbar__body">
              <p>Thanks for the report. Our team will review this.</p>
            </div>
          </div>
        </div>
    </div>
`;

const toggleFlagUserModal = () => {
  document
    .getElementsByClassName('flag-user-modal-subcont')[0]
    .classList.toggle('hidden');
};

function toggleModActionsMenu() {
  document.querySelector('.mod-actions-menu').classList.toggle('showing');
  document.querySelector('.mod-actions-menu-btn').classList.toggle('hidden');
}

/** This initializes the mod actions button on the article show page (app/views/articles/show.html.erb). */
export function initializeActionsPanel() {
  // eslint-disable-next-line no-undef
  const user = userData();
  const { authorId: articleAuthorId, path } = document.getElementById(
    'article-show-container',
  ).dataset;

  const modActionsMenuHTML = `<iframe src=${path}/actions_panel></iframe>`;
  const modActionsMenuIconHTML = `<div class="mod-actions-menu-btn">
  <svg xmlns="http://www.w3.org/2000/svg" width="54px" height="54px" viewBox="-8 -8 40 40" class="crayons-icon actions-menu-svg" role="img" aria-labelledby=""><title id="">Moderation</title><path d="M3.783 2.826L12 1l8.217 1.826a1 1 0 01.783.976v9.987a6 6 0 01-2.672 4.992L12 23l-6.328-4.219A6 6 0 013 13.79V3.802a1 1 0 01.783-.976zM5 4.604v9.185a4 4 0 001.781 3.328L12 20.597l5.219-3.48A4 4 0 0019 13.79V4.604L12 3.05 5 4.604zM13 10h3l-5 7v-5H8l5-7v5z"></path></svg>
</div>
`;

  if (user.id !== articleAuthorId && user.trusted) {
    document.querySelector('.mod-actions-menu').innerHTML = modActionsMenuHTML;
    document.getElementById(
      'mod-actions-menu-btn-area',
    ).innerHTML = modActionsMenuIconHTML;
    document.querySelector(
      '.flag-user-modal-container',
    ).innerHTML = flagUserModalHTML;
    document
      .querySelector('.mod-actions-menu-btn')
      .addEventListener('click', toggleModActionsMenu);
    document
      .getElementById('open-flag-user-modal')
      .addEventListener('click', toggleFlagUserModal);
  }
}
