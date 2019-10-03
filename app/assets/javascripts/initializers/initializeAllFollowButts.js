/* eslint-disable no-param-reassign */

'use strict';

// private

function addFollowText(butt, style) {
  if (style === 'small') {
    butt.textContent = '+';
  } else if (style === 'follow-back') {
    butt.textContent = '+ FOLLOW BACK';
  } else {
    butt.textContent = '+ FOLLOW';
  }
}

function addFollowingText(butt, style) {
  if (style === 'small') {
    butt.textContent = '✓';
  } else {
    butt.textContent = '✓ FOLLOWING';
  }
}

function assignState(butt, newState) {
  var style = JSON.parse(butt.dataset.info).style;
  butt.classList.add('showing');
  if (newState === 'follow' || newState === 'follow-back') {
    butt.dataset.verb = 'unfollow';
    butt.classList.remove('following-butt');
    if (newState === 'follow-back') {
      addFollowText(butt, newState);
    } else if (newState === 'follow') {
      addFollowText(butt, style);
    }
  } else if (newState === 'login') {
    addFollowText(butt, style);
  } else if (newState === 'self') {
    butt.dataset.verb = 'self';
    butt.textContent = 'EDIT PROFILE';
  } else {
    butt.dataset.verb = 'follow';
    addFollowingText(butt, style);
    butt.classList.add('following-butt');
  }
}

function addModalEventListener(butt) {
  assignState(butt, 'login');
  butt.onclick = function onClick(e) {
    e.preventDefault();
    // eslint-disable-next-line no-undef
    showModal('follow-button');
  };
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

function handleFollowButtPress(butt) {
  var buttonDataInfo = JSON.parse(butt.dataset.info);
  var formData = new FormData();
  formData.append('followable_type', buttonDataInfo.className);
  formData.append('followable_id', buttonDataInfo.id);
  formData.append('verb', butt.dataset.verb);
  getCsrfToken().then(sendFetch('follow-creation', formData));
}

function handleOptimisticButtRender(butt) {
  if (butt.dataset.verb === 'self') {
    window.location.href = '/settings';
  } else if (butt.dataset.verb === 'login') {
    // eslint-disable-next-line no-undef
    showModal('follow-button');
  } else {
    // Handles actual following of tags/users
    try {
      // lets try grab the event buttons info data attribute user id
      var evFabUserId = JSON.parse(butt.dataset.info).id;
      var requestVerb = butt.dataset.verb;
      // now for all follow action buttons
      document
        .querySelectorAll('.follow-action-button')
        .forEach(function checkAndAssignState(fab) {
          try {
            // lets check they have info data attributes
            if (fab.dataset.info) {
              // and attempt to parse those, to grab that buttons info user id
              var fabUserId = JSON.parse(fab.dataset.info).id;
              // now does that user id match our event buttons user id?
              if (fabUserId && fabUserId === evFabUserId) {
                // yes - time to assign the same state!
                assignState(fab, requestVerb);
              }
            }
          } catch (err) {
            // return;
          }
        });
    } catch (err) {
      return;
    }

    handleFollowButtPress(butt);
  }
}

function addButtClickHandle(response, butt) {
  // currently lacking error handling
  var buttInfo = JSON.parse(butt.dataset.info);
  assignInitialButtResponse(response, butt);
  butt.onclick = function onclick(e) {
    e.preventDefault();
    handleOptimisticButtRender(butt);
  };
}

function handleTagButtAssignment(user, butt, buttInfo) {
  var buttAssignmentBoolean =
    JSON.parse(user.followed_tags)
      .map(function getId(followedTag) {
        return followedTag.id;
      })
      .indexOf(buttInfo.id) !== -1;
  var buttAssignmentBoolText = buttAssignmentBoolean ? 'true' : 'false';
  addButtClickHandle(buttAssignmentBoolText, butt);
  // shouldNotFetch = true;
}

function fetchButt(butt, buttInfo) {
  butt.dataset.fetched = 'fetched';
  var dataRequester;
  if (window.XMLHttpRequest) {
    dataRequester = new XMLHttpRequest();
  } else {
    dataRequester = new ActiveXObject('Microsoft.XMLHTTP');
  }
  dataRequester.onreadystatechange = function onreadystatechange() {
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

function initializeFollowButt(butt) {
  var user = userData();
  // eslint-disable-next-line no-restricted-globals
  var deviceWidth = window.innerWidth > 0 ? window.innerWidth : screen.width;
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
  } else {
    if (butt.dataset.fetched === 'fetched') {
      return;
    }
    fetchButt(butt, buttInfo);
  }
}

function initializeAllFollowButts() {
  var followButts = document.getElementsByClassName('follow-action-button');
  for (var i = 0; i < followButts.length; i += 1) {
    initializeFollowButt(followButts[i]);
  }
}
