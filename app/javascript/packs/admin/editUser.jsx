import { showUserModal } from './users/editUserModals';
import { initializeDropdown } from '@utilities/dropdownUtils';

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

initializeDropdown({
  triggerElementId: 'more-details-dropdown-trigger',
  dropdownContentId: 'more-details-dropdown',
});

document.body.addEventListener('click', showUserModal);
