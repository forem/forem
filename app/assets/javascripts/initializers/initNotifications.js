'use strict';

/* global checkUserLoggedIn instantClick InstantClick sendHapticMessage */

function markNotificationsAsRead() {
  setTimeout(() => {
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
      xmlhttp.onreadystatechange = () => {};

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
    document.getElementById('notifications-container') === null &&
    checkUserLoggedIn()
  ) {
    var xmlhttp;
    if (window.XMLHttpRequest) {
      xmlhttp = new XMLHttpRequest();
    } else {
      xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
    }
    xmlhttp.onreadystatechange = () => {
      if (xmlhttp.readyState === XMLHttpRequest.DONE) {
        var count = xmlhttp.response;
        if (Number.isNaN(count)) {
          document
            .getElementById('notifications-number')
            .classList.remove('showing');
        } else if (count !== '0' && count !== undefined && count !== '') {
          document.getElementById('notifications-number').innerHTML =
            xmlhttp.response;
          document
            .getElementById('notifications-number')
            .classList.add('showing');
          if (instantClick) {
            InstantClick.removeExpiredKeys('force');
            setTimeout(() => {
              InstantClick.preload(
                document.getElementById('notifications-link').href,
                'force',
              );
            }, 30);
          }
        } else {
          document
            .getElementById('notifications-number')
            .classList.remove('showing');
        }
      }
    };

    xmlhttp.open('GET', '/notifications/counts', true);
    xmlhttp.send();
  }
}

// map over the array of elements and apply a callback function to click event
function addOnClickHandlerToButtons(className, callBack) {
  var butts = document.getElementsByClassName(className);
  var i;
  var butt;
  for (i = 0; i < butts.length; i += 1) {
    butt = butts[i];
    butt.addEventListener('click', callBack);
  }
}

function onClickReactionButton(event) {
  event.preventDefault();
  sendHapticMessage('medium');
  var thisButt = event.target;
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
    .then(response => {
      if (response.status === 200) {
        response.json().then(successCb);
      }
    });
}

function onClickReply(event) {
  event.preventDefault();
  var thisButt = event.target;
  document
    .getElementById('comment-form-for-' + thisButt.dataset.reactableId)
    .classList.add('showing');
  thisButt.innerHTML = '';
  setTimeout(() => {
    document
      .getElementById('comment-textarea-for-' + thisButt.dataset.reactableId)
      .focus();
  }, 30);
}

function initReactions() {
  setTimeout(() => {
    if (document.getElementById('notifications-container')) {
      addOnClickHandlerToButtons('reaction-button', onClickReactionButton);
      addOnClickHandlerToButtons('toggle-reply-form', onClickReply);
    }
  }, 180);
}

function removeShowingClass() {
  document.getElementById('notifications-number').classList.remove('showing');
}

function listenForNotificationsBellClick() {
  setTimeout(() => {
    document
      .getElementById('notifications-link')
      .addEventListener('click', removeShowingClass);
  }, 180);
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
        .then(response => {
          if (response.status === 200) {
            response.text().then(html => {
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

function initNotifications() {
  fetchNotificationsCount();
  markNotificationsAsRead();
  initReactions();
  listenForNotificationsBellClick();
  initPagination();
  initLoadMoreButton();
}
