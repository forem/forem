import { initializeActionsPanel } from '../actionsPanel/initializeActionsPanelToggle';
import { initializeFlagUserModal } from './flagUserModal';

if (!window.parent.document.location.pathname.endsWith('/mod')) {
  initializeActionsPanel();
  initializeFlagUserModal();
}
