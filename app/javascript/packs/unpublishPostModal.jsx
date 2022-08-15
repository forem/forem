/* eslint-disable no-restricted-globals */
import { closeWindowModal, showWindowModal } from '@utilities/showModal';
import { request } from '@utilities/http';

async function confirmAdminUnpublishPost(id, username, slug) {
  try {
    const response = await request(`/articles/${id}/admin_unpublish`, {
      method: 'PATCH',
      body: JSON.stringify({ id, username, slug }),
      credentials: 'same-origin',
    });

    const outcome = await response.json();

    /* eslint-disable no-restricted-globals */
    if (outcome.message == 'success') {
      window.top.location.assign(`${window.location.origin}${outcome.path}`);
    } else {
      top.addSnackbarItem({
        message: `Error: ${outcome.message}`,
        addCloseButton: true,
      });
    }
  } catch (error) {
    top.addSnackbarItem({
      message: `Error: ${error}`,
      addCloseButton: true,
    });
  }

  closeWindowModal(window.parent.document);
}

let modalContents;

/**
 * Helper function to handle finding and caching modal content. Since our Preact modal helper works by duplicating HTML content,
 * and our modals rely on IDs to label form controls, we remove the original hidden content from the DOM to avoid ID conflicts.
 *
 * @param {string} modalContentSelector The CSS selector used to identify the correct modal content
 */
function getModalContents(modalContentSelector) {
  if (!modalContents) {
    const modalContentElement =
      window.parent.document.querySelector(modalContentSelector);
    modalContents = modalContentElement.innerHTML;
    modalContentElement.remove();
  }

  return modalContents;
}

function activateModalUnpublishBtn(id, username, slug) {
  const unpublishBtn = window.parent.document.getElementById(
    'confirm-unpublish-post-action',
  );

  unpublishBtn?.addEventListener('click', () => {
    confirmAdminUnpublishPost(id, username, slug);
  });
}

/**
 * Shows or hides the flag user modal.
 */
export function toggleUnpublishPostModal(event) {
  event.preventDefault;
  const { articleId, authorUsername, articleSlug, modalContentSelector } =
    event.target.dataset;

  showWindowModal({
    document: window.parent.document,
    modalContent: getModalContents(modalContentSelector),
    title: 'Unpublish post',
    size: 'small',
    onOpen: () => {
      activateModalUnpublishBtn(articleId, authorUsername, articleSlug);
    },
  });
}
