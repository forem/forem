import { showUserModal } from './users/editUserModals';
import { initializeDropdown } from '@utilities/dropdownUtils';

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

document.body.addEventListener('click', showUserModal);
