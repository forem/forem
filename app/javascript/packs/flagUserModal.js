const modalSnackbarHTML = `
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
`;

const toggleFlagUserModal = () => {
  document
    .querySelector('.flag-user-modal-container')
    .classList.toggle('hidden');
};

const flashSnackbar = (snackbar) => {
  setTimeout(() => {
    snackbar.classList.remove('flex');
  }, 3000);
  snackbar.classList.add('flex');
};

export function initializeFlagUserModal() {
  // eslint-disable-next-line no-undef
  const user = userData();
  const {
    authorId: articleAuthorId,
    authorClassName: articleAuthorClassName,
  } = document.getElementById('article-show-container').dataset;

  const flagUserModalHTML = `
<div class="crayons-modal crayons-modal--s absolute flag-user-modal">
  <div class="crayons-modal__box">
    <header class="crayons-modal__box__header flag-user-modal-header">
      <h2>Flag User</h2>
      <button type="button" class="crayons-btn crayons-btn--icon crayons-btn--ghost modal-header-close-icon">
        <svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
        </svg>
      </button>
    </header>
    <div class="crayons-modal__box__body flag-user-modal-body">
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
            data-reactable-id="${articleAuthorId}"
            data-category="vomit"
            data-reactable-type="${articleAuthorClassName}">
          <label for="vomit-all" class="crayons-field__label">
            Make all posts by this author less visible
            <p class="crayons-field__description">
              This author consistently posts content that violates DEV's code of conduct because it is harassing, offensive or spammy.
            </p>
          </label>
        </div>
        <a href="/report-abuse?url=${document.location}" class="fs-base abuse-report-link">Report other inappropriate conduct</a>
      </div>
      <div class="buttons-container">
        <a href="#" class="crayons-btn" id="confirm-flag-user-action">Confirm action</a>
        <a href="#" class="crayons-btn" id="cancel-flag-user-action">Cancel</a>
      </div>
    </div>
  </div>
  <div class="crayons-modal__overlay"></div>
</div>
`;

  if (user.id !== articleAuthorId && user.trusted) {
    const modContainer = document.getElementById('mod-container');

    document.querySelector(
      '.modal-snackbar-container',
    ).innerHTML = modalSnackbarHTML;
    document.querySelector(
      '.flag-user-modal-container',
    ).innerHTML = flagUserModalHTML;
    modContainer.addEventListener('load', () => {
      modContainer.contentWindow.document
        .getElementById('open-flag-user-modal')
        .addEventListener('click', toggleFlagUserModal);
    });
  }

  // Event listeners to Close the Modal
  document
    .querySelector('.crayons-modal__overlay')
    .addEventListener('click', toggleFlagUserModal);

  document
    .querySelector('.modal-header-close-icon')
    .addEventListener('click', toggleFlagUserModal);

  document
    .getElementById('confirm-flag-user-action')
    .addEventListener('click', () => {
      if (!document.getElementById('vomit-all').checked) {
        alert('No Selection Made!');
      } else {
        toggleFlagUserModal();
      }
    });

  document
    .getElementById('cancel-flag-user-action')
    .addEventListener('click', toggleFlagUserModal);

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
              response.json().then(flashSnackbar(snackbar));
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
