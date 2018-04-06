function initNotifications() {
  fetchNotificationsCount();
  markNotificationsAsRead();
  initReactions();
  listenForNotificationsBellClick();
}

function markNotificationsAsRead() {
  setTimeout(function () {
    if (document.getElementById('notifications-container')) {
      var xmlhttp;
      if (window.XMLHttpRequest) {
        xmlhttp = new XMLHttpRequest();
      } else {
        xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
      }
      xmlhttp.onreadystatechange = function () {
      };

      var csrfToken = document.querySelector("meta[name='csrf-token']").content;

      xmlhttp.open('Post', '/notifications/reads', true);
      xmlhttp.setRequestHeader('X-CSRF-Token', csrfToken);
      xmlhttp.send();
    }
  }, 120);
}

function fetchNotificationsCount() {
  if (document.getElementById('notifications-container') == null && checkUserLoggedIn()) {
    var xmlhttp;
    if (window.XMLHttpRequest) {
      xmlhttp = new XMLHttpRequest();
    } else {
      xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
    }
    xmlhttp.onreadystatechange = function () {
      if (xmlhttp.readyState == XMLHttpRequest.DONE) {
        var count = xmlhttp.response;
        if (isNaN(count)) {
          document.getElementById('notifications-number').classList.remove('showing');
        } else if (count != '0' && count != undefined && count != "") {
          document.getElementById('notifications-number').innerHTML = xmlhttp.response;
          document.getElementById('notifications-number').classList.add('showing');
          if(instantClick){
            InstantClick.removeExpiredKeys("force");
            setTimeout(function(){
              InstantClick.preload(document.getElementById("notifications-link").href, "force");
            },30)
          }
        } else {
          document.getElementById('notifications-number').classList.remove('showing');
        }
      }
    };
    var timeString = (Date.now()).toString();
    xmlhttp.open('Get', '/notifications/counts', true);
    xmlhttp.send();
  }
  else if (document.getElementById("notifications-container") == null) {
    document.getElementById("notifications-number").innerHTML = "1";
    document.getElementById("notifications-number").classList.add("showing");
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
              }
            });
        };
      }
      var butts = document.getElementsByClassName('toggle-reply-form');
      for (var i = 0; i < butts.length; i++) {
        var butt = butts[i];
        butt.onclick = function (event) {
          event.preventDefault();
          var thisButt = this;
          document.getElementById('comment-form-for-' + thisButt.dataset.reactableId).classList.add('showing');
          thisButt.innerHTML = '';
          setTimeout(function () {
            document.getElementById('comment-textarea-for-' + thisButt.dataset.reactableId).focus();
          }, 30);
        };
      }
    }
  }, 180);
}

function listenForNotificationsBellClick() {
  setTimeout(function () {
    document.getElementById('notifications-link').onclick = function () {
      document.getElementById('notifications-number').classList.remove('showing');
    };
  }, 180);
}
