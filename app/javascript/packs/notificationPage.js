import { embedGists } from '../utilities/gist';
import { sendHapticMessage } from '../utilities/sendHapticMessage';
import { showModalAfterError } from '../utilities/showUserAlertModal';
import { initializeSubscribeButton } from './subscribeButton';

function handleEmbedGists() {
  const targetNode = document.querySelector('#articles-list');
  targetNode && embedGists(targetNode);
}

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

export function initializeNotificationsPage() {
  const container = document.getElementById('notifications-container');
  if (!container || container.dataset.notificationsInitialized === 'true') {
    return;
  }
  container.dataset.notificationsInitialized = 'true';

  handleEmbedGists();
  markNotificationsAsRead();
  initReactions();
  initFilter();
  initPagination();
  initLoadMoreButton();
}

window.Forem = window.Forem || {};
window.Forem.initializeNotificationsPage = initializeNotificationsPage;

window.InstantClick?.on('change', () => {
  initializeNotificationsPage();
});

initializeNotificationsPage();
