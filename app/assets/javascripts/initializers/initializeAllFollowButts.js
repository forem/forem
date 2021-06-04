/* global showLoginModal */

function initializeAllFollowButts() {
  var followButts = document.getElementsByClassName('follow-action-button');
  for (var i = 0; i < followButts.length; i++) {
    if (!followButts[i].className.includes('follow-user')) {
      initializeFollowButt(followButts[i]);
    }
  }
}

function fetchUserFollowStatuses(idButtonHash) {
  const url = new URL('/follows/bulk_show', document.location);
  const searchParams = new URLSearchParams();
  Object.keys(idButtonHash).forEach((id) => {
    searchParams.append('ids[]', id);
  });
  searchParams.append('followable_type', 'User');
  url.search = searchParams;

  fetch(url, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((idStatuses) => {
      Object.keys(idStatuses).forEach(function (id) {
        addButtClickHandle(idStatuses[id], idButtonHash[id]);
      });
    });
}

function initializeUserFollowButtons(buttons) {
  if (buttons.length > 0) {
    var userIds = {};
    for (var i = 0; i < buttons.length; i++) {
      var userStatus = document.body.getAttribute('data-user-status');
      if (userStatus === 'logged-out') {
        addModalEventListener(buttons[i]);
      } else {
        var userId = JSON.parse(buttons[i].dataset.info).id;
        userIds[userId] = buttons[i];
      }
    }

    if (Object.keys(userIds).length > 0) {
      fetchUserFollowStatuses(userIds);
    }
  }
}

function initializeUserFollowButts() {
  var buttons = document.getElementsByClassName(
    'follow-action-button follow-user',
  );
  initializeUserFollowButtons(buttons);
}

//private

function initializeFollowButt(butt) {
  var user = userData();
  var buttInfo = JSON.parse(butt.dataset.info);
  var userStatus = document
    .getElementsByTagName('body')[0]
    .getAttribute('data-user-status');
  if (userStatus === 'logged-out') {
    addModalEventListener(butt);
    return;
  }
  if (buttInfo.className === 'Tag' && user) {
    handleTagButtAssignment(user, butt, buttInfo);
    return;
  } else {
    if (butt.dataset.fetched === 'fetched') {
      return;
    }
    fetchButt(butt, buttInfo);
  }
}

function addModalEventListener(butt) {
  assignState(butt, 'login');
  butt.onclick = function (e) {
    e.preventDefault();
    showLoginModal();
    return;
  };
}

function fetchButt(butt, buttInfo) {
  butt.dataset.fetched = 'fetched';
  var dataRequester;
  if (window.XMLHttpRequest) {
    dataRequester = new XMLHttpRequest();
  } else {
    dataRequester = new ActiveXObject('Microsoft.XMLHTTP');
  }
  dataRequester.onreadystatechange = function () {
    if (
      dataRequester.readyState === XMLHttpRequest.DONE &&
      dataRequester.status === 200
    ) {
      addButtClickHandle(dataRequester.response, butt);
    }
  };
  dataRequester.open(
    'GET',
    '/follows/' + buttInfo.id + '?followable_type=' + buttInfo.className,
    true,
  );
  dataRequester.send();
}

function addButtClickHandle(response, butt) {
  // currently lacking error handling
  var buttInfo = JSON.parse(butt.dataset.info);
  assignInitialButtResponse(response, butt);
  butt.onclick = function (e) {
    e.preventDefault();
    handleOptimisticButtRender(butt);
  };
  butt.dataset.clickInitialized = 'true';
}

function handleTagButtAssignment(user, butt, buttInfo) {
  var buttAssignmentBoolean =
    JSON.parse(user.followed_tags)
      .map(function (a) {
        return a.id;
      })
      .indexOf(buttInfo.id) !== -1;

  var buttAssignmentBoolText = buttAssignmentBoolean ? 'true' : 'false';
  addButtClickHandle(buttAssignmentBoolText, butt);
}

function assignInitialButtResponse(response, butt) {
  butt.classList.add('showing');
  if (response === 'true' || response === 'mutual') {
    assignState(butt, 'unfollow');
  } else if (response === 'follow-back') {
    assignState(butt, 'follow-back');
  } else if (response === 'false') {
    assignState(butt, 'follow');
  } else if (response === 'self') {
    assignState(butt, 'self');
  } else {
    assignState(butt, 'login');
  }
}

function handleOptimisticButtRender(butt) {
  if (butt.dataset.verb === 'self') {
    window.location.href = '/settings';
  } else if (butt.dataset.verb === 'login') {
    showLoginModal();
  } else {
    // Handles actual following of tags/users
    try {
      //lets try grab the event buttons info data attribute user id
      var evFabUserId = JSON.parse(butt.dataset.info).id;
      var requestVerb = butt.dataset.verb;
      //now for all follow action buttons
      let actionButtons = document.getElementsByClassName(
        'follow-action-button',
      );
      Array.from(actionButtons).forEach(function (fab) {
        try {
          //lets check they have info data attributes
          if (fab.dataset.info) {
            //and attempt to parse those, to grab that buttons info user id
            var fabUserId = JSON.parse(fab.dataset.info).id;
            //now does that user id match our event buttons user id?
            if (fabUserId && fabUserId === evFabUserId) {
              //yes - time to assign the same state!
              assignState(fab, requestVerb);
            }
          }
        } catch (err) {
          return;
        }
      });
    } catch (err) {
      return;
    }

    handleFollowButtPress(butt);
  }
}

function handleFollowButtPress(butt) {
  var buttonDataInfo = JSON.parse(butt.dataset.info);
  var formData = new FormData();
  formData.append('followable_type', buttonDataInfo.className);
  formData.append('followable_id', buttonDataInfo.id);
  formData.append('verb', butt.dataset.verb);
  getCsrfToken().then(sendFetch('follow-creation', formData));
}

function assignState(butt, newState) {
  var style = JSON.parse(butt.dataset.info).style;
  var followStyle = JSON.parse(butt.dataset.info).followStyle;
  butt.classList.add('showing');
  if (newState === 'follow' || newState === 'follow-back') {
    butt.dataset.verb = 'unfollow';
    butt.classList.remove('crayons-btn--outlined');
    if (followStyle === 'primary') {
      butt.classList.add('crayons-btn--primary');
    } else if (followStyle === 'secondary') {
      butt.classList.add('crayons-btn--secondary');
    }
    if (newState === 'follow-back') {
      addFollowText(butt, newState);
    } else if (newState === 'follow') {
      addFollowText(butt, style);
    }
  } else if (newState === 'login') {
    addFollowText(butt, style);
  } else if (newState === 'self') {
    butt.dataset.verb = 'self';
    butt.textContent = 'Edit profile';
  } else {
    butt.dataset.verb = 'follow';
    addFollowingText(butt, style);
    butt.classList.remove('crayons-btn--primary');
    butt.classList.remove('crayons-btn--secondary');
    butt.classList.add('crayons-btn--outlined');
  }
}

function addFollowText(butt, style) {
  if (style === 'small') {
    butt.textContent = '+';
  } else if (style === 'follow-back') {
    butt.textContent = 'Follow back';
  } else {
    butt.textContent = 'Follow';
  }
}

function addFollowingText(butt, style) {
  if (style === 'small') {
    butt.textContent = '✓';
  } else {
    butt.textContent = 'Following';
  }
}
