import {
  closeWindowModal,
  showWindowModal,
  WINDOW_MODAL_ID,
} from '@utilities/showModal';
import { request } from '@utilities/http';

async function flagUser({ reactableType, category, reactableId }) {
  const body = JSON.stringify({
    category,
    reactable_type: reactableType,
    reactable_id: reactableId,
  });

  try {
    const response = await request('/reactions', {
      method: 'POST',
      body,
      credentials: 'same-origin',
    });

    const outcome = await response.json();

    if (outcome.result === 'create') {
      top.addSnackbarItem({
        message: 'All posts by this author will be less visible.',
        addCloseButton: true,
      });
    } else if (outcome.result === 'destroy') {
      top.addSnackbarItem({
        message: 'You have unflagged this author successfully.',
        addCloseButton: true,
      });
    } else {
      top.addSnackbarItem({
        message: `Response from server: ${JSON.stringify(outcome)}`,
        addCloseButton: true,
      });
    }
  } catch (error) {
    top.addSnackbarItem({
      message: error,
      addCloseButton: true,
    });
  }

  closeModal();
}

function closeModal() {
  closeWindowModal();
}

function addModalListeners() {
  const modalWindow = window.parent.document;
  const modal = modalWindow.getElementById(WINDOW_MODAL_ID);
  const confirmFlagUserRadio = modalWindow.getElementById(
    'flag-user-radio-input',
  );
  const confirmFlagUserBtn = modalWindow.getElementById(
    'confirm-flag-user-action',
  );
  const reportLink = modalWindow.getElementById('report-inappropriate-content');
  const errorMsg = modal.querySelector('#unselected-radio-error');
  const { category, reactableType, userId } = confirmFlagUserBtn.dataset;

  confirmFlagUserBtn?.addEventListener('click', () => {
    if (confirmFlagUserRadio.checked) {
      errorMsg.innerText = '';
      flagUser({
        category,
        reactableType,
        reactableId: userId,
      });
    } else {
      errorMsg.innerText = 'You must check the radio button first.';
    }
  });
  reportLink?.addEventListener('click', (event) => {
    event.preventDefault();
    // console.log(event.target.dataset.reportAbuseLink);
  });
}

const modalContents = new Map();

/**
 * Helper function to handle finding and caching modal content. Since our Preact modal helper works by duplicating HTML content,
 * and our modals rely on IDs to label form controls, we remove the original hidden content from the DOM to avoid ID conflicts.
 *
 * @param {string} modalContentSelector The CSS selector used to identify the correct modal content
 */
const getModalContents = (modalContentSelector) => {
  if (!modalContents.has(modalContentSelector)) {
    const modalContentElement =
      window.parent.document.querySelector(modalContentSelector);
    const modalContent = modalContentElement.innerHTML;

    modalContentElement.remove();
    modalContents.set(modalContentSelector, modalContent);
  }

  return modalContents.get(modalContentSelector);
};

export function toggleFlagUserModal(event) {
  event.preventDefault;
  const { modalTitle, modalSize, modalContentSelector } = event.target.dataset;
  showWindowModal({
    document: window.parent.document,
    modalContent: getModalContents(modalContentSelector),
    title: modalTitle,
    size: modalSize,
    onOpen: addModalListeners,
  });
}
