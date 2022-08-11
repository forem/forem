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
        message: outcome.message,
        addCloseButton: true,
      });

      updateBtnFlow(btnAction, username);
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

function capitalizeFirst(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

function updateBtnFlow(btnAction, username) {
  const btn = window.parent.document
    .getElementById('mod-container')
    .contentDocument.querySelector(`#${btnAction}-user-btn`);
  const oppositeAction = btnAction == 'suspend' ? 'unsuspend' : 'suspend';

  btn.textContent = `${capitalizeFirst(oppositeAction)} ${username}`;
  btn.dataset.modalTitle = `${capitalizeFirst(oppositeAction)} ${username}`;
  btn.id = `${oppositeAction}-user-btn`;
  btn.dataset.modalContentSelector = `#${oppositeAction}-modal-content`;

  oppositeAction == 'suspend'
    ? btn.classList.add('c-btn--destructive')
    : btn.classList.remove('c-btn--destructive');
}

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

function checkReason(event) {
  const { btnAction, reasonSelector, userId, username } = event.target.dataset;
  const modal = window.parent.document.getElementById(WINDOW_MODAL_ID);
  const actionReason = modal.querySelector(reasonSelector).value;

  if (!actionReason) {
    modal.querySelector(`.${btnAction}-reason-error`).innerText =
      'You must give a reason for this action.';
  } else {
    suspendOrUnsuspendUser({
      event,
      btnAction,
      userId,
      username,
      actionReason,
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

export function toggleSuspendUserModal(event) {
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
