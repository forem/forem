/* eslint-disable no-restricted-globals */
import { closeWindowModal, showWindowModal } from '@utilities/showModal';
import { request } from '@utilities/http';

const unpublishAllPosts = async ({ event, endpoint }) => {
  event.preventDefault();
  event.target.disabled = true;

  try {
    const http_request = await request(endpoint, { method: 'POST' });
    const response = await http_request.json();

    top.addSnackbarItem({
      message: response.message,
      addCloseButton: true,
    });
  } catch (error) {
    top.addSnackbarItem({
      message: `Error: ${error}`,
      addCloseButton: true,
    });
  }

  event.target.disabled = false;
  closeWindowModal(window.parent.document);
};

const modalContents = new Map();

function getConfirmation(event) {
  const confirmation = confirm('Are you sure you want to unpublish all posts?');
  const endpoint = event.target.dataset.formAction;

  if (confirmation) {
    unpublishAllPosts({ event, endpoint });
  }
}

/**
 * Helper function to handle finding and caching modal content. Since our Preact modal helper works by duplicating HTML content,
 * and our modals rely on IDs to label form controls, we remove the original hidden content from the DOM to avoid ID conflicts.
 *
 * @param {string} modalContentSelector The CSS selector used to identify the correct modal content
 */
function getModalContents(modalContentSelector) {
  if (!modalContents.has(modalContentSelector)) {
    const modalContentElement =
      window.parent.document.querySelector(modalContentSelector);
    const modalContent = modalContentElement.innerHTML;

    modalContentElement.remove();
    modalContents.set(modalContentSelector, modalContent);
  }

  return modalContents.get(modalContentSelector);
}

function activateUnpublishAllPostsBtn() {
  const unpublishAllPostsBtn = window.parent.document.getElementById(
    'unpublish-all-posts-submit-btn',
  );

  unpublishAllPostsBtn.addEventListener('click', getConfirmation);
}

export function toggleUnpublishAllPostsModal() {
  const unpublishAllPostsBtn = document.getElementById(
    'unpublish-all-posts-btn',
  );

  const { modalTitle, modalSize, modalContentSelector } =
    unpublishAllPostsBtn.dataset;

  showWindowModal({
    document: window.parent.document,
    modalContent: getModalContents(modalContentSelector),
    title: modalTitle,
    size: modalSize,
    onOpen: activateUnpublishAllPostsBtn,
  });
}
