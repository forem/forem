import { initializeCommentDate } from './initializers/initializeCommentDate';
import { initializeCommentPreview } from './initializers/initializeCommentPreview';
import { initializeTimeFixer } from './initializers/initializeTimeFixer';
import { initializeNotifications } from './initializers/initializeNotifications';
import { initializeDateHelpers } from './initializers/initializeDateTimeHelpers';
import { initializeSettings } from './initializers/initializeSettings';
import {
  showUserAlertModal,
  showModalAfterError,
} from '@utilities/showUserAlertModal';

initializeCommentDate();
initializeCommentPreview();
initializeSettings();
initializeNotifications();
initializeTimeFixer();
initializeDateHelpers();

InstantClick.on('change', () => {
  initializeCommentDate();
  initializeCommentPreview();
  initializeSettings();
  initializeNotifications();
});

window.showUserAlertModal = showUserAlertModal;
window.showModalAfterError = showModalAfterError;
