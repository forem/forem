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
  const notificationsNumber = document.getElementById('notifications-number');
  if (
    notificationsNumber &&
    document.getElementById('notifications-container')
  ) {
    notificationsNumber.classList.add('hidden');
  }

  const notificationsLink = document.getElementById('notifications-link');
  if (notificationsLink) {
    notificationsLink.onclick = function () {
      const badge = document.getElementById('notifications-number');
      if (badge) {
        badge.classList.add('hidden');
      }
    };
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
