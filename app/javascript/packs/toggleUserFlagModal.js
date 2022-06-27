import {
  closeWindowModal,
  showWindowModal,
  WINDOW_MODAL_ID,
} from '@utilities/showModal';
import { request } from '@utilities/http';

function closeModal() {
  closeWindowModal(window.parent.document);
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

  confirmFlagUserBtn?.addEventListener('click', () => {
    console.log('hello');
  });
  reportLink?.addEventListener('click', closeModal);
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

export function showModal(event) {
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
