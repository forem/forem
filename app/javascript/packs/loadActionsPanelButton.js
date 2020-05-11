import { initializeActionsPanel } from '../actionsPanel/initializeActionsPanelToggle';
import { initializeFlagUserModal } from './flagUserModal';

if (!top.document.location.pathname.endsWith('/mod')) {
  initializeActionsPanel();
  initializeFlagUserModal();
}
