import { initializeCommentDate } from './initializers/initializeCommentDate';
import { initializeCommentPreview } from './initializers/initializeCommentPreview';
import { initializeTimeFixer } from './initializers/initializeTimeFixer';
import { initializeNotifications } from './initializers/initializeNotifications';
import {
  showUserAlertModal,
  showModalAfterError,
} from '@utilities/showUserAlertModal';

initializeCommentDate();
initializeCommentPreview();
initializeNotifications();
initializeTimeFixer();

InstantClick.on('change', () => {
  initializeNotifications();
});

window.showUserAlertModal = showUserAlertModal;
window.showModalAfterError = showModalAfterError;
