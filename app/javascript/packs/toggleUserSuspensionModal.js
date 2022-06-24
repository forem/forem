import {
  closeWindowModal,
  showWindowModal,
  WINDOW_MODAL_ID,
} from '@utilities/showModal';
import { request } from '@utilities/http';

const suspendOrUnsuspendUser = async ({
  event,
  btnAction,
  userId,
  suspendOrUnsuspendReason,
}) => {
  event.preventDefault();
  closeModal();

  try {
    const response = await request(
      `/admin/member_manager/users/${userId}/user_status`,
      {
        method: 'PATCH',
        body: JSON.stringify({
          id: userId,
          user: {
            note_for_current_role: suspendOrUnsuspendReason,
            user_status: btnAction == 'suspend' ? 'Suspended' : 'Good standing',
          },
        }),
        credentials: 'same-origin',
      },
    );

    const outcome = await response.json();

    if (outcome.success) {
      top.addSnackbarItem({
        message: outcome.message,
        addCloseButton: true,
      });
    } else {
      top.addSnackbarItem({
        message: 'Error: something went wrong.',
        addCloseButton: true,
      });
    }
  } catch (error) {
    top.addSnackbarItem({
      message: `Error: ${error}`,
      addCloseButton: true,
    });
  }
};

function closeModal() {
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

function checkReason(event) {
  const { btnAction, reasonSelector, userId } = event.target.dataset;
  const suspendUnsuspendModal =
    window.parent.document.getElementById(WINDOW_MODAL_ID);
  const suspendOrUnsuspendReason =
    suspendUnsuspendModal.querySelector(reasonSelector).value;

  if (!suspendOrUnsuspendReason) {
    suspendUnsuspendModal.querySelector(
      '.suspend-unsuspend-reason-error',
    ).innerText = 'You must give a reason for this action.';
  } else {
    suspendOrUnsuspendUser({
      event,
      btnAction,
      userId,
      suspendOrUnsuspendReason,
    });
  }
}

function activateModalSubmitBtn() {
  const suspendBtn = window.parent.document.getElementById(
    'submit-user-suspend-btn',
  );
  const unsuspendBtn = window.parent.document.getElementById(
    'submit-user-unsuspend-btn',
  );

  suspendBtn?.addEventListener('click', checkReason);
  unsuspendBtn?.addEventListener('click', checkReason);
}

export function toggleModal(event) {
  event.preventDefault;
  const { modalTitle, modalSize, modalContentSelector } = event.target.dataset;
  showWindowModal({
    document: window.parent.document,
    modalContent: getModalContents(modalContentSelector),
    title: modalTitle,
    size: modalSize,
    onOpen: activateModalSubmitBtn,
  });
}
