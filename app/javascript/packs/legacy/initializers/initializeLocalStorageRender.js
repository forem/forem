import { browserStoreCache } from '../utilities/browserStoreCache';
import { initializeBaseUserData } from './initializeBaseUserData';
import { initializeBillboardVisibility } from './initializeBillboardVisibility';

export function initializeLocalStorageRender() {
  try {
    var userData = browserStoreCache('get');
    if (userData) {
      document.body.dataset.user = userData;
      initializeBaseUserData();
      initializeReadingListIcons();
      initializeBillboardVisibility();
    }
  } catch (err) {
    browserStoreCache('remove');
  }
}
