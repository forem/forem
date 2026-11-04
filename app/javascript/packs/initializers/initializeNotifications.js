import { checkUserLoggedIn } from '../../utilities/checkUserLoggedIn';
// eslint-disable-next-line no-redeclare
/* global InstantClick, instantClick */

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
