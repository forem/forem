'use strict';

/* global checkUserLoggedIn, instantClick, InstantClick, sendHapticMessage */

function markNotificationsAsRead() {
  setTimeout(function() {
    if (document.getElementById('notifications-container')) {
      let xmlhttp;
      const locationAsArray = window.location.pathname.split('/');
      // Use regex to ensure only numbers in the original string are converted to integers
      const parsedLastParam = parseInt(
        locationAsArray[locationAsArray.length - 1].replace(/[^0-9]/g, ''),
        10,
      );

      if (window.XMLHttpRequest) {
        xmlhttp = new XMLHttpRequest();
      } else {
        xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
      }
      xmlhttp.onreadystatechange = function() {};

      const csrfToken = document.querySelector("meta[name='csrf-token']")
        .content;

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
    let xmlhttp;
    if (window.XMLHttpRequest) {
      xmlhttp = new XMLHttpRequest();
    } else {
      xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
    }
    xmlhttp.onreadystatechange = function() {
      if (xmlhttp.readyState === XMLHttpRequest.DONE) {
        const count = xmlhttp.response;
        const notificationsNumber = document.getElementById(
          'notifications-number',
        );

        if (Number.isNaN(count)) {
          notificationsNumber.classList.remove('showing');
        } else if (count !== '0' && count !== undefined && count !== '') {
          notificationsNumber.innerHTML = xmlhttp.response;
          notificationsNumber.classList.add('showing');

          if (instantClick) {
            InstantClick.removeExpiredKeys('force');
            setTimeout(function() {
              InstantClick.preload(
                document.getElementById('notifications-link').href,
                'force',
              );
            }, 30);
          }
        } else {
          notificationsNumber.classList.remove('showing');
        }
      }
    };

    xmlhttp.open('GET', '/notifications/counts', true);
    xmlhttp.send();
  }
}

function initReactions() {
  setTimeout(function() {
    if (document.getElementById('notifications-container')) {
      const reactionButtons = document.getElementsByClassName(
        'reaction-button',
      );
      for (const i = 0; i < reactionButtons.length; i += 1) {
        const butt = reactionButtons[i];

        butt.addEventListener('click', function(event) {
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
            .then(function(response) {
              if (response.status === 200) {
                response.json().then(successCb);
              }
            });
        });
      }

      const replyButtons = document.getElementsByClassName('toggle-reply-form');
      for (const i = 0; i < replyButtons.length; i += 1) {
        const butt = replyButtons[i];
        butt.addEventListener('click', function(event) {
          event.preventDefault();
          var thisButt = this;
          document
            .getElementById('comment-form-for-' + thisButt.dataset.reactableId)
            .classList.add('showing');
          thisButt.innerHTML = '';
          setTimeout(function() {
            document
              .getElementById(
                'comment-textarea-for-' + thisButt.dataset.reactableId,
              )
              .focus();
          }, 30);
        });
      }
    }
  }, 180);
}

function listenForNotificationsBellClick() {
  setTimeout(function() {
    document.getElementById('notifications-link').onclick = function() {
      document
        .getElementById('notifications-number')
        .classList.remove('showing');
    };
  }, 180);
}

function initPagination() {
  // paginators appear at the end of each block of HTML notifications sent by
  // the server, each time we paginate we're only interested in the last one
  const paginators = document.getElementsByClassName('notifications-paginator');
  const paginator = paginators[paginators.length - 1];

  if (paginator) {
    window
      .fetch(paginator.dataset.paginationPath, {
        method: 'GET',
        credentials: 'same-origin',
      })
      .then(function(response) {
        if (response.status === 200) {
          response.text().then(function(html) {
            const notificationsList = html.trim();

            if (notificationsList) {
              paginator.innerHTML = notificationsList;
              initReactions();
            } else {
              // no more notifications to load, we hide the load more wrapper
              const button = document.getElementById('load-more-button');
              button.style.display = 'none';
            }
          });
        }
      });
  }
}

function initLoadMoreButton() {
  const button = document.getElementById('load-more-button');
  button.addEventListener('click', initPagination);
}

function initNotifications() {
  fetchNotificationsCount();
  markNotificationsAsRead();
  initReactions();
  listenForNotificationsBellClick();
  initPagination();
  initLoadMoreButton();
}
