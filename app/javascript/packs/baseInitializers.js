import { initializeCommentDate } from './initializers/initializeCommentDate';
import { initializeCommentPreview } from './initializers/initializeCommentPreview';
import { initializeTimeFixer } from './initializers/initializeTimeFixer';
import { initializeNotifications } from './initializers/initializeNotifications';
import { initializeDateHelpers } from './initializers/initializeDateTimeHelpers';
import { initializeSettings } from './initializers/initializeSettings';
import { initializeTurnstile } from '../initializers/initializeTurnstile';
import { initializeGifVideos } from '@utilities/gifVideo';
import { initializeMermaidDiagrams } from '@utilities/mermaidDiagrams';
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
initializeGifVideos(document);
initializeMermaidDiagrams(document);
initializeTurnstile();

InstantClick.on('change', () => {
  initializeCommentDate();
  initializeCommentPreview();
  initializeSettings();
  initializeNotifications();
  initializeDateHelpers(); // Re-format dates on page navigation
  initializeGifVideos(document);
  initializeMermaidDiagrams(document);
  initializeTurnstile();
});

InstantClick.on('restore', initializeTurnstile);

window.showUserAlertModal = showUserAlertModal;
window.showModalAfterError = showModalAfterError;
