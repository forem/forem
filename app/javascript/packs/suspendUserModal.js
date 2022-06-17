import { showWindowModal } from '@utilities/showModal';
import { request } from '@utilities/http';

const suspendUser = async ({ event, userId, username, suspensionReason }) => {
  event.preventDefault();
  closeSuspendUserModal();

  try {
    const response = await request(
      `/admin/member_manager/users/${userId}/user_status`,
      {
        method: 'PATCH',
        body: JSON.stringify({
          id: userId,
          user: {
            note_for_current_role: suspensionReason,
            user_status: 'Suspend',
          },
        }),
        credentials: 'same-origin',
      },
    );

    const outcome = await response.json();

    /* eslint-disable no-restricted-globals */
    if (outcome.success) {
      top.addSnackbarItem({
        message: `Success: "${username}" has been suspended.`,
        addCloseButton: true,
      });
    } else {
      top.addSnackbarItem({
        message: `Error: something went wrong; ${username} NOT suspended.`,
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

function closeSuspendUserModal() {
  window.parent.document
    .querySelector('#window-modal .crayons-modal__dismiss')
    .click();
}

const modalContents = new Map();

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

function checkSuspensionReason(event) {
  const { userId, username, suspensionReasonSelector } = event.target.dataset;
  const suspendUserModal =
    window.parent.document.getElementById('window-modal');
  const suspensionReason = suspendUserModal.querySelector(
    suspensionReasonSelector,
  ).value;

  if (!suspensionReason) {
    suspendUserModal
      .querySelector('#suspension-reason-error')
      .classList.remove('hidden');
  } else {
    suspendUser({ event, userId, username, suspensionReason });
  }
}

function activateSubmitSuspendBtn() {
  const submitSuspendBtn = window.parent.document.getElementById(
    'submit-user-suspension-btn',
  );

  submitSuspendBtn.addEventListener('click', checkSuspensionReason);
}

export function toggleSuspendUserModal() {
  const suspendUserBtn = document.getElementById('suspend-user-btn');
  const { modalTitle, modalSize, modalContentSelector } =
    suspendUserBtn.dataset;
  showWindowModal({
    document: window.parent.document,
    modalContent: getModalContents(modalContentSelector),
    title: modalTitle,
    size: modalSize,
    onOpen: activateSubmitSuspendBtn,
  });
}
