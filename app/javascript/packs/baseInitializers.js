import { initializeCommentDate } from './initializers/initializeCommentDate';
import { initializeCommentPreview } from './initializers/initializeCommentPreview';
import { initializeNotifications } from './initializers/initializeNotifications';
import { initializeDateHelpers } from './initializers/initializeDateTimeHelpers';
import {
  showUserAlertModal,
  showModalAfterError,
} from '@utilities/showUserAlertModal';

initializeCommentDate();
initializeCommentPreview();
initializeNotifications();
initializeDateHelpers();

InstantClick.on('change', () => {
  initializeNotifications();
});

window.showUserAlertModal = showUserAlertModal;
window.showModalAfterError = showModalAfterError;
