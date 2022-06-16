import { showWindowModal } from '@utilities/showModal';
import { request } from '@utilities/http';

const suspendUser = async (event) => {
  const { userId, username, suspensionReasonId } = event.target.dataset;
  const suspensionReason = document.getElementById(suspensionReasonId).value;

  event.preventDefault();

  try {
    const response = await request(
      `/admin/member_manager/users/${userId}/user_status`,
      {
        method: 'PATCH',
        body: JSON.stringify({
          id: userId,
          user_params: {
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

const modalContents = new Map();

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

function activateSuspendBtn() {
  const btn = window.parent.document.getElementById(
    'submit-user-suspension-btn',
  );

  if (btn) {
    // console.log('we got a btn!');
  }
}

export function toggleSuspendUserModal() {
  const suspendUserBtn = document.getElementById('suspend-user-btn');
  const { modalTitle, modalSize, modalContentSelector } =
    suspendUserBtn.dataset;
  showWindowModal({
    modalContent: getModalContents(modalContentSelector),
    title: modalTitle,
    size: modalSize,
    onOpen: activateSuspendBtn(),
  });
}
