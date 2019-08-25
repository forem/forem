'use strict';

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
        xmlhttp = new window.ActiveXObject('Microsoft.XMLHTTP');
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
    document.getElementById('notifications-container') == null &&
    checkUserLoggedIn()
  ) {
    var xmlhttp;
    if (window.XMLHttpRequest) {
      xmlhttp = new XMLHttpRequest();
    } else {
      xmlhttp = new window.ActiveXObject('Microsoft.XMLHTTP');
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
          if (window.instantClick) {
            window.InstantClick.removeExpiredKeys('force');
            setTimeout(() => {
              window.InstantClick.preload(
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

function initReactionButtonEvent(event) {
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
    .then(response => {
      if (response.status === 200) {
        response.json().then(successCb);
      }
    });
}

function initReactions() {
  setTimeout(() => {
    if (document.getElementById('notifications-container')) {
      var reactButts = document.getElementsByClassName('reaction-button');
      for (var i = 0; i < reactButts.length; i += 1) {
        var reactButt = reactButts[i];
        reactButt.onclick = event => {
          initReactionButtonEvent(event);
        };
      }
      var replyButts = document.getElementsByClassName('toggle-reply-form');
      for (var j = 0; j < replyButts.length; j += 1) {
        var replyButt = replyButts[j];
        replyButt.onclick = event => {
          event.preventDefault();
          var thisButt = this;
          document
            .getElementById('comment-form-for-' + thisButt.dataset.reactableId)
            .classList.add('showing');
          thisButt.innerHTML = '';
          setTimeout(() => {
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
  setTimeout(() => {
    document.getElementById('notifications-link').onclick = () => {
      document
        .getElementById('notifications-number')
        .classList.remove('showing');
    };
  }, 180);
}

function initPagination() {
  var el = document.getElementById('notifications-pagination');
  if (el) {
    window
      .fetch(el.dataset.paginationPath, {
        method: 'GET',
        credentials: 'same-origin',
      })
      .then(response => {
        if (response.status === 200) {
          response.text().then(html => {
            el.innerHTML = html;
            initReactions();
          });
        }
      });
  }
}

function initNotifications() {
  fetchNotificationsCount();
  markNotificationsAsRead();
  initReactions();
  listenForNotificationsBellClick();
  initPagination();
}
