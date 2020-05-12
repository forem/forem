import { initializeActionsPanel } from '../actionsPanel/initializeActionsPanelToggle';
import { initializeFlagUserModal } from './flagUserModal';

// eslint-disable-next-line no-restricted-globals
if (!top.document.location.pathname.endsWith('/mod')) {
  initializeActionsPanel();
  initializeFlagUserModal();
}
