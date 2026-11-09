import { sendHapticMessage } from '../../utilities/sendHapticMessage';
import { checkUserLoggedIn } from '../../utilities/checkUserLoggedIn';
import { showModalAfterError } from '../../utilities/showUserAlertModal';
import { initializeSubscribeButton } from '../../packs/subscribeButton';
// eslint-disable-next-line no-redeclare
/* global InstantClick, instantClick, getCsrfToken, sendFetch */

function markNotificationsAsRead() {
  if (navigator.userAgent === 'ForemWebView/1') {
    return;
  }
  setTimeout(() => {
    if (document.getElementById('notifications-container')) {
      getCsrfToken().then((csrfToken) => {
        const locationAsArray = window.location.pathname.split('/');
        // Use regex to ensure only numbers in the original string are converted to integers
        const parsedLastParam = parseInt(
          locationAsArray[locationAsArray.length - 1].replace(/[^0-9]/g, ''),
          10,
        );

        const options = {
          method: 'POST',
          headers: { 'X-CSRF-Token': csrfToken },
        };

        if (Number.isInteger(parsedLastParam)) {
          fetch(`/notifications/reads?org_id=${parsedLastParam}`, options);
        } else {
          fetch('/notifications/reads', options);
        }
      });
    }
  }, 450);
}

function updateNotificationsBadge(rawCount) {
  const badge = document.getElementById('notifications-number');
  if (!badge) {
    return;
  }
  const count = parseInt(rawCount, 10);
  if (Number.isNaN(count) || count <= 0) {
    badge.classList.add('hidden');
    return;
  }
  badge.textContent = count > 50 ? '50+' : String(count);
  badge.classList.remove('hidden');
}

function refreshNotificationsBadge() {
  // The notifications page marks everything as read, so keep the badge hidden.
  if (
    !checkUserLoggedIn() ||
    document.getElementById('notifications-container') ||
    window.location.pathname.startsWith('/notifications')
  ) {
    return;
  }
  window
    .fetch('/notifications/counts', { credentials: 'same-origin' })
    .then((response) => (response.ok ? response.text() : null))
    .then((text) => {
      if (text !== null) {
        updateNotificationsBadge(text);
      }
    })
    .catch(() => {});
}

// Refresh the badge when a long-lived tab becomes visible again.
function listenForTabVisibility() {
  if (window.__notificationsVisibilityListenerAttached) {
    return;
  }
  window.__notificationsVisibilityListenerAttached = true;
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      refreshNotificationsBadge();
    }
  });
}

function fetchNotificationsCount() {
  refreshNotificationsBadge();
  listenForTabVisibility();

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

function initReactions() {
  setTimeout(() => {
    if (document.getElementById('notifications-container')) {
      let butts = document.getElementsByClassName('reaction-button');

      for (let i = 0; i < butts.length; i++) {
        const butt = butts[i];
        butt.setAttribute('aria-pressed', butt.classList.contains('reacted'));

        butt.onclick = function (event) {
          event.preventDefault();
          sendHapticMessage('medium');
          const thisButt = this;
          thisButt.classList.add('reacted');

          function successCb(response) {
            if (response.result === 'create') {
              thisButt.classList.add('reacted');
              thisButt.setAttribute('aria-pressed', true);
            } else {
              thisButt.classList.remove('reacted');
              thisButt.setAttribute('aria-pressed', false);
            }
          }

          const formData = new FormData();
          formData.append('reactable_type', thisButt.dataset.reactableType);
          formData.append('category', thisButt.dataset.category);
          formData.append('reactable_id', thisButt.dataset.reactableId);

          getCsrfToken()
            .then(sendFetch('reaction-creation', formData))
            .then((response) => {
              if (response.status === 200) {
                response.json().then(successCb);
              } else {
                showModalAfterError({
                  response,
                  element: 'reaction',
                  action_ing: 'updating',
                  action_past: 'updated',
                });
              }
            });
        };
      }

      butts = document.getElementsByClassName('toggle-reply-form');

      for (let i = 0; i < butts.length; i++) {
        const butt = butts[i];

        butt.onclick = function (event) {
          event.preventDefault();
          const thisButt = this;
          document
            .getElementById(`comment-form-for-${thisButt.dataset.reactableId}`)
            .classList.remove('hidden');
          thisButt.classList.add('hidden');
          thisButt.classList.remove('inline-flex');
          setTimeout(() => {
            document
              .getElementById(
                `comment-textarea-for-${thisButt.dataset.reactableId}`,
              )
              .focus();
          }, 30);
        };
      }
    }
  }, 180);
}

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

function initFilter() {
  const notificationsFilterSelect = document.getElementById(
    'notifications-filter__select',
  );
  const changeNotifications = (event) => {
    window.location.href = event.target.value;
  };
  if (notificationsFilterSelect) {
    notificationsFilterSelect.addEventListener('change', changeNotifications);
  }
}

function initPagination() {
  // paginators appear after each block of HTML notifications sent by the server
  const paginators = document.getElementsByClassName('notifications-paginator');
  if (paginators && paginators.length > 0) {
    const paginator = paginators[paginators.length - 1];

    if (paginator) {
      window
        .fetch(paginator.dataset.paginationPath, {
          method: 'GET',
          credentials: 'same-origin',
        })
        .then((response) => {
          if (response.status === 200) {
            response.text().then((html) => {
              const markup = html.trim();

              if (markup) {
                const container = document.getElementById('articles-list');

                const newNotifications = document.createElement('div');
                newNotifications.innerHTML = markup;

                paginator.remove();
                container.append(newNotifications);

                initReactions();
              } else {
                // no more notifications to load, we hide the load more wrapper
                const button = document.getElementById('load-more-button');
                if (button) {
                  button.style.display = 'none';
                }
                paginator.remove();
              }

              initializeSubscribeButton();
            });
          }
        });
    }
  }
}

function initLoadMoreButton() {
  const button = document.getElementById('load-more-button');
  if (button) {
    button.addEventListener('click', initPagination);
  }
}

/**
 * Initializes the navbar notifications bell and `/notifications` page interactions for signed-in users.
 */
export function initializeNotifications() {
  if (!checkUserLoggedIn()) {
    return;
  }

  fetchNotificationsCount();
  listenForNotificationsBellClick();

  if (!document.getElementById('notifications-container')) {
    return;
  }

  markNotificationsAsRead();
  initReactions();
  initFilter();
  initPagination();
  initLoadMoreButton();
}
