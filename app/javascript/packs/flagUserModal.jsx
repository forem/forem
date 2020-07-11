import { h } from 'preact';
import PropTypes from 'prop-types';
import { request } from '../utilities/http';
import { Button } from '@crayons/Button/Button';

export function toggleFlagUserModal() {
  const modalContainer = document.querySelector('.flag-user-modal-container');
  modalContainer.classList.toggle('hidden');

  if (!modalContainer.classList.contains('hidden')) {
    window.scrollTo(0, 0);
    document.querySelector('body').style.height = '100vh';
    document.querySelector('body').style.overflowY = 'hidden';
  } else {
    document.querySelector('body').style.height = 'inherit';
    document.querySelector('body').style.overflowY = 'inherit';
  }
}

async function confirmFlagUser(e) {
  e.preventDefault();
  const vomitAllOption = document.getElementById('vomit-all');

  if (vomitAllOption.checked) {
    const body = JSON.stringify({
      reactable_type: vomitAllOption.dataset.reactableType,
      category: vomitAllOption.dataset.category,
      reactable_id: vomitAllOption.dataset.reactableId,
    });

    try {
      const response = await request('/reactions', {
        method: 'POST',
        body,
      });

      const outcome = await response.json();

      if (outcome.result === 'create') {
        // eslint-disable-next-line no-restricted-globals
        top.addSnackbarItem({
          message: 'All posts by this author will be less visible.',
          addCloseButton: true,
        });
      } else if (outcome.result === null) {
        // eslint-disable-next-line no-restricted-globals
        top.addSnackbarItem({
          message:
            "It seems you've already reduced the vibilsity of this author's posts.",
          addCloseButton: true,
        });
      } else {
        // eslint-disable-next-line no-restricted-globals
        top.addSnackbarItem({
          message: `Response from server: ${JSON.stringify(outcome)}`,
          addCloseButton: true,
        });
      }
    } catch (error) {
      // eslint-disable-next-line no-restricted-globals
      top.addSnackbarItem({
        message: error,
        addCloseButton: true,
      });
    }
  } else {
    // eslint-disable-next-line no-restricted-globals
    top.addSnackbarItem({
      message: 'No selection made!',
      addCloseButton: true,
    });
  }
  toggleFlagUserModal();
}

export function FlagUserModal({ modCenterArticleUrl, authorId }) {
  return (
    <div class="crayons-modal crayons-modal--s absolute flag-user-modal">
      <div class="crayons-modal__box">
        <header class="crayons-modal__box__header flag-user-modal-header">
          <h2>Flag User</h2>
          <button
            type="button"
            class="crayons-btn crayons-btn--icon crayons-btn--ghost modal-header-close-icon"
          >
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              class="crayons-icon"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
            </svg>
          </button>
        </header>
        <div class="crayons-modal__box__body flag-user-modal-body">
          <span>
            Thanks for keeping DEV safe. Here is what you can do to flag this
            user:
          </span>
          <div class="crayons-fields">
            <div class="crayons-field crayons-field--radio">
              <input
                type="radio"
                id="vomit-all"
                name="flag-user"
                class="crayons-radio"
                data-reactable-id={authorId}
                data-category="vomit"
                data-reactable-type="User"
              />
              <label htmlFor="vomit-all" class="crayons-field__label">
                Make all posts by this author less visible
                <p class="crayons-field__description">
                  This author consistently posts content that violates DEV's
                  code of conduct because it is harassing, offensive or spammy.
                </p>
              </label>
            </div>
            <a
              href={`/report-abuse?url=${
                modCenterArticleUrl
                  ? `${document.location.origin}${modCenterArticleUrl}`
                  : document.location
              }`}
              class="fs-base abuse-report-link"
            >
              Report other inappropriate conduct
            </a>
          </div>
          <div class="buttons-container">
            <Button
              class="crayons-btn crayons-btn--danger mr-2"
              id="confirm-flag-user-action"
              onClick={confirmFlagUser}
            >
              Confirm action
            </Button>
            <Button
              class="crayons-btn crayons-btn--secondary"
              id="cancel-flag-user-action"
              onClick={toggleFlagUserModal}
            >
              Cancel
            </Button>
          </div>
        </div>
      </div>
      <div
        role="presentation"
        class="crayons-modal__overlay"
        onClick={toggleFlagUserModal}
        onKeyUp={toggleFlagUserModal}
      />
    </div>
  );
}

FlagUserModal.displayName = 'FlagUserModal';
FlagUserModal.propTypes = {
  moderationUrl: PropTypes.string.isRequired,
};
