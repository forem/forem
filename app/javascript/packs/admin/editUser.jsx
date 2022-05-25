import { initializeUserModal } from './users/userModalActions';
import { initializeDropdown } from '@utilities/dropdownUtils';
import { showWindowModal } from '@utilities/showModal';

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

const openModal = async (event) => {
  const { dataset } = event.target;

  if (!Object.prototype.hasOwnProperty.call(dataset, 'modalContentSelector')) {
    // We're not trying to trigger a modal.
    return;
  }

  event.preventDefault();

  const { modalTitle, modalSize, modalContentSelector } = dataset;

  showWindowModal({
    contentSelector: modalContentSelector,
    title: modalTitle,
    size: modalSize,
    onOpen: () => {
      initializeUserModal(dataset);
    },
  });
};

document.body.addEventListener('click', openModal);
