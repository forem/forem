import { showUserModal } from './users/userModalActions';
import { initializeDropdown } from '@utilities/dropdownUtils';

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

document.body.addEventListener('click', showUserModal);
