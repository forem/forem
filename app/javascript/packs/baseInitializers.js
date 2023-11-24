import { initializeCommentDate } from './initializers/initializeCommentDate';
import { initializeTimeFixer } from './initializers/initializeTimeFixer';
import { initializeNotifications } from './initializers/initializeNotifications';
import { initializeDateHelpers } from './initializers/initializeDateTimeHelpers';
import { initializeSettings } from './initializers/initializeSettings';
import {
  showUserAlertModal,
  showModalAfterError,
} from '@utilities/showUserAlertModal';

initializeCommentDate();
initializeSettings();
initializeNotifications();
initializeTimeFixer();
initializeDateHelpers();

InstantClick.on('change', () => {
  initializeCommentDate();
  initializeSettings();
  initializeNotifications();
});

window.showUserAlertModal = showUserAlertModal;
window.showModalAfterError = showModalAfterError;
