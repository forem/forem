import {
  showWindowModal,
  closeWindowModal,
  WINDOW_MODAL_ID,
} from '@utilities/showModal';

// The GDPR Delete Requests table may have up to 50 entries at once. Instead of adding an event listener for every row, we
// instead listen for clicks anywhere in the table, and only trigger the modal if the click target was a confirm delete button
document
  .getElementById('gdpr-delete-requests-content')
  ?.addEventListener('click', ({ target }) => {
    const {
      dataset: { username, gdprFormAction },
    } = target;
    if (gdprFormAction) {
      handleConfirmDelete(username, gdprFormAction);
    }
  });

const handleConfirmDelete = (username, formAction) => {
  showWindowModal({
    title: `Are you sure you have deleted all external data for @${username}?`,
    contentSelector: '#gdpr-confirm-delete-modal',
    onOpen: () => {
      // Set the action of the form
      document.getElementById(WINDOW_MODAL_ID).querySelector('form').action =
        formAction;

      // Update cancel button to close the modal
      document
        .querySelector(`#${WINDOW_MODAL_ID} .js-gdpr-cancel-deleted`)
        .addEventListener('click', () => closeWindowModal());
    },
  });
};
