import { closeWindowModal, showWindowModal } from '@utilities/showModal';
import { request } from '@utilities/http';

const unpublishAllPosts = async (event) => {
  event.preventDefault();
  const { userId } = event.target.dataset;

  const noteTextarea = window.parent.document.getElementById('note_content');
  const params = { id: userId, note: { content: noteTextarea.value } };

  try {
    const response = await request(
      `/admin/member_manager/users/${userId}/unpublish_all_articles`,
      {
        method: 'POST',
        body: JSON.stringify(params),
        credentials: 'same-origin',
      },
    );

    const outcome = await response.json();

    top.addSnackbarItem({
      message: outcome.message,
      addCloseButton: true,
    });
  } catch (error) {
    top.addSnackbarItem({
      message: `Error: ${error}`,
      addCloseButton: true,
    });
  }

  closeWindowModal(window.parent.document);
};

const modalContents = new Map();

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

  unpublishAllPostsBtn.addEventListener('click', unpublishAllPosts);
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
