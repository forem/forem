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
  document.querySelector('flag-user-modal-subcont').classList.toggle('hidden');
};

export function initializeFlagUserModal() {
  // eslint-disable-next-line no-undef
  const user = userData();
  const { authorId: articleAuthorId } = document.getElementById(
    'article-show-container',
  ).dataset;

  if (user.id !== articleAuthorId && user.trusted) {
    const modContainer = document.getElementById('mod-container');

    document.querySelector(
      '.flag-user-modal-container',
    ).innerHTML = flagUserModalHTML;
    modContainer.addEventListener('load', () => {
      modContainer.contentWindow.document
        .getElementById('open-flag-user-modal')
        .addEventListener('click', toggleFlagUserModal);
    });
  }

  document
    .getElementById('confirm-flag-user-action')
    .addEventListener('click', (e) => {
      e.preventDefault();
      const vomitAllOption = document.getElementById('vomit-all');
      const vomitAllSnackbar = document.getElementById('vomit-all-snackbar');

      const flagUserApiCall = (body, snackbar) => {
        getCsrfToken()
          .then(sendFetch('reaction-creation', body))
          .then((response) => {
            if (response.status === 200) {
              response.json().then(snackbar.classList.add('flex'));
            }
          });
      };

      if (vomitAllOption.checked) {
        const formData = new FormData();
        formData.append('reactable_type', vomitAllOption.dataset.reactableType);
        formData.append('category', vomitAllOption.dataset.category);
        formData.append('reactable_id', vomitAllOption.dataset.reactableId);

        flagUserApiCall(formData, vomitAllSnackbar);
      }
    });
}
