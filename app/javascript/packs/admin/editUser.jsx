import {
  initializeAddOrganizationContent,
  initializeAddRoleContent,
  initializeAdjustCreditBalanceContent,
  initializeUnpublishAllPostsContent,
} from './users/userModalActions';
import { initializeDropdown } from '@utilities/dropdownUtils';
import { showWindowModal } from '@utilities/showModal';

const modalContentInitializers = {
  '.js-add-organization': initializeAddOrganizationContent,
  '.js-add-role': initializeAddRoleContent,
  '.js-adjust-balance': initializeAdjustCreditBalanceContent,
  '.js-unpublish-all-posts': initializeUnpublishAllPostsContent,
};

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

const openModal = async (event) => {
  const { dataset } = event.target;

  if (!Object.prototype.hasOwnProperty.call(dataset, 'modalTrigger')) {
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
      // enableEvents(modalContentSelector);
      modalContentInitializers[modalContentSelector]?.(dataset);
    },
  });
};

document.body.addEventListener('click', openModal);
