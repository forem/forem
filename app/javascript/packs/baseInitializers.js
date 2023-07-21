import { initializeCommentDate } from './initializers/initializeCommentDate';
import { initializeCommentPreview } from './initializers/initializeCommentPreview';
import { toggleFooterVisibility } from './initializers/initializeFooter';
import { initializeTimeFixer } from './initializers/initializeTimeFixer';
import { initializeNotifications } from './initializers/initializeNotifications';
import { initializeDateHelpers } from './initializers/initializeDateTimeHelpers';
import {
  showUserAlertModal,
  showModalAfterError,
} from '@utilities/showUserAlertModal';

toggleFooterVisibility();
initializeCommentDate();
initializeCommentPreview();
initializeNotifications();
initializeTimeFixer();
initializeDateHelpers();

InstantClick.on('change', () => {
  initializeCommentDate();
  initializeCommentPreview();
  initializeNotifications();
});

window.showUserAlertModal = showUserAlertModal;
window.showModalAfterError = showModalAfterError;
