/* eslint-disable no-restricted-globals */
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
  username,
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
        message: `Success: "${username}" has been ${btnAction}ed.`,
        addCloseButton: true,
      });
    } else {
      top.addSnackbarItem({
        message: `Error: something went wrong; ${username} NOT ${btnAction}ed.`,
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

function checkReason(event) {
  const { btnAction, reasonSelector, userId, username } = event.target.dataset;
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
      username,
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
