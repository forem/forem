import { closeWindowModal, showWindowModal } from '@utilities/showModal';
import { request } from '@utilities/http';

const unpublishAllPosts = async (event) => {
  event.preventDefault();
  const { userId } = event.target.dataset;

  try {
    const response = await request(
      `/admin/member_manager/users/${userId}/unpublish_all_articles`,
      {
        method: 'POST',
        body: JSON.stringify({ id: userId }),
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
    modalContent: window.parent.document.querySelector(modalContentSelector),
    title: modalTitle,
    size: modalSize,
    onOpen: activateUnpublishAllPostsBtn,
  });
}
