/* global checkUserLoggedIn, instantClick, InstantClick, sendHapticMessage, showModalAfterError */

function initNotifications() {
  fetchNotificationsCount();
  markNotificationsAsRead();
  initReactions();
  listenForNotificationsBellClick();
  initFilter();
  initPagination();
  initLoadMoreButton();
}

function markNotificationsAsRead() {
  setTimeout(function () {
    if (document.getElementById('notifications-container')) {
      var xmlhttp;
      var locationAsArray = window.location.pathname.split('/');
      // Use regex to ensure only numbers in the original string are converted to integers
      var parsedLastParam = parseInt(
        locationAsArray[locationAsArray.length - 1].replace(/[^0-9]/g, ''),
        10,
      );

      if (window.XMLHttpRequest) {
        xmlhttp = new XMLHttpRequest();
      } else {
        xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
      }
      xmlhttp.onreadystatechange = function () {};

      var csrfToken = document.querySelector("meta[name='csrf-token']").content;

      if (Number.isInteger(parsedLastParam)) {
        xmlhttp.open(
          'Post',
          '/notifications/reads?org_id=' + parsedLastParam,
          true,
        );
      } else {
        xmlhttp.open('Post', '/notifications/reads', true);
      }
      xmlhttp.setRequestHeader('X-CSRF-Token', csrfToken);
      xmlhttp.send();
    }
  }, 450);
}

function fetchNotificationsCount() {
  if (
    document.getElementById('notifications-container') == null &&
    checkUserLoggedIn()
  ) {
    // Prefetch notifications page
    if (instantClick) {
      InstantClick.removeExpiredKeys('force');
      setTimeout(function () {
        InstantClick.preload(
          document.getElementById('notifications-link').href,
          'force',
        );
      }, 30);
    }
  }
}

function initReactions() {
  setTimeout(function () {
    if (document.getElementById('notifications-container')) {
      var butts = document.getElementsByClassName('reaction-button');

      for (var i = 0; i < butts.length; i++) {
        var butt = butts[i];
        butt.onclick = function (event) {
          event.preventDefault();
          sendHapticMessage('medium');
          var thisButt = this;
          thisButt.classList.add('reacted');

          function successCb(response) {
            if (response.result === 'create') {
              thisButt.classList.add('reacted');
            } else {
              thisButt.classList.remove('reacted');
            }
          }

          var formData = new FormData();
          formData.append('reactable_type', thisButt.dataset.reactableType);
          formData.append('category', thisButt.dataset.category);
          formData.append('reactable_id', thisButt.dataset.reactableId);

          getCsrfToken()
            .then(sendFetch('reaction-creation', formData))
            .then(function (response) {
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
          var thisButt = this;
          document
            .getElementById('comment-form-for-' + thisButt.dataset.reactableId)
            .classList.remove('hidden');
          thisButt.classList.add('hidden');
          thisButt.classList.remove('inline-flex');
          setTimeout(function () {
            document
              .getElementById(
                'comment-textarea-for-' + thisButt.dataset.reactableId,
              )
              .focus();
          }, 30);
        };
      }
    }
  }, 180);
}

function listenForNotificationsBellClick() {
  var notificationsLink = document.getElementById('notifications-link');
  if (notificationsLink) {
    setTimeout(function () {
      notificationsLink.onclick = function () {
        document.getElementById('notifications-number').classList.add('hidden');
      };
    }, 180);
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
        .then(function (response) {
          if (response.status === 200) {
            response.text().then(function (html) {
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
