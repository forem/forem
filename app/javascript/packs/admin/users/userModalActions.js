import { WINDOW_MODAL_ID } from '@utilities/showModal';

const getModalContent = () => document.getElementById(WINDOW_MODAL_ID);

export const initializeAddOrganizationContent = ({ userName, userId }) => {
  const modalContent = getModalContent();

  // Set the user ID for the form
  modalContent.querySelector('#organization_membership_user_id').value =
    parseInt(userId, 10);
  // Display the user's name in the modal
  modalContent.querySelector('.js-user-name').innerText = userName;
};
