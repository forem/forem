import { checkUserLoggedIn } from '../../utilities/checkUserLoggedIn';
// eslint-disable-next-line no-redeclare
/* global InstantClick, instantClick */

/**
 * Preloads the notifications page link via InstantClick for signed-in users.
 */
function fetchNotificationsCount() {
  if (
    document.getElementById('notifications-container') == null &&
    checkUserLoggedIn()
  ) {
    // Prefetch notifications page
    if (instantClick) {
      InstantClick.removeExpiredKeys('force');
      setTimeout(() => {
        const notificationsLink = document.getElementById('notifications-link');
        if (notificationsLink) {
          InstantClick.preload(notificationsLink.href, 'force');
        }
      }, 30);
    }
  }
}

/**
 * Hides the unread notifications count badge when the notifications bell link is clicked.
 */
function listenForNotificationsBellClick() {
  const notificationsLink = document.getElementById('notifications-link');
  if (notificationsLink) {
    setTimeout(() => {
      notificationsLink.onclick = function () {
        document.getElementById('notifications-number')?.classList.add('hidden');
      };
    }, 180);
  }
}

/**
 * Initializes the navbar notifications bell and delegates to the notifications page initializer if present.
 */
export function initializeNotifications() {
  if (!checkUserLoggedIn()) {
    return;
  }

  fetchNotificationsCount();
  listenForNotificationsBellClick();

  if (
    document.getElementById('notifications-container') &&
    typeof window.Forem?.initializeNotificationsPage === 'function'
  ) {
    window.Forem.initializeNotificationsPage();
  }
}
