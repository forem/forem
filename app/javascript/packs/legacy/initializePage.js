/*
  global initializeLocalStorageRender, initializeBodyData,
  initializeAllTagEditButtons, initializeUserFollowButts,
  initializeCommentsPage,
  initializeRuntimeBanner,
  initializeCreditsPage,
  initializeOnboardingTaskCard,
  initScrolling, nextPage:writable,
  fetching:writable, done:writable, initializePaymentPointers,
  initializeBroadcast
*/

import { browserStoreCache } from './utilities/browserStoreCache';
import { initScrolling } from './initializers/initScrolling';
import {
  initializeAllTagEditButtons,
} from './initializers/initializeAllTagEditButtons';
import { initializeBaseUserData } from './initializers/initializeBaseUserData';
import {
  initializeBillboardVisibility,
} from './initializers/initializeBillboardVisibility';
import { initializeBodyData } from './initializers/initializeBodyData';
import { initializeBroadcast } from './initializers/initializeBroadcast';
import { initializeCommentsPage } from './initializers/initializeCommentsPage';
import { initializeCreditsPage } from './initializers/initializeCreditsPage';
import { initializeLocalStorageRender } from './initializers/initializeLocalStorageRender';
import { initializeOnboardingTaskCard } from './initializers/initializeOnboardingTaskCard';
import { initializePaymentPointers } from './initializers/initializePaymentPointers';
import { initializeReadingListIcons } from './initializers/initializeReadingListIcons';
import { userData } from './utilities/userData';


export function initializePage() {
  initializeLocalStorageRender();
  initializeBodyData();

  var waitingForDataLoad = setInterval(function wait() {
    if (document.body.getAttribute('data-loaded') === 'true') {
      clearInterval(waitingForDataLoad);
      if (document.body.getAttribute('data-user-status') === 'logged-in') {
        initializeBaseUserData();
        initializeAllTagEditButtons();
      }
      initializeBroadcast();
      initializeReadingListIcons();
      initializeBillboardVisibility();
      if (document.getElementById('sidebar-additional')) {
        document.getElementById('sidebar-additional').classList.add('showing');
      }
    }
  }, 1);

  initializePaymentPointers();
  initializeCommentsPage();
  initializeCreditsPage();
  initializeOnboardingTaskCard();

  nextPage = 0;
  fetching = false;
  done = false;
  setTimeout(function undone() {
    done = false;
  }, 300);
  if (!initScrolling.called) {
    initScrolling();
  }
}
