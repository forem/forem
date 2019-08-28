'use strict';

function addFollowText(butt, style) {
  var btnToAddFollowText = butt;
  if (style === 'small') {
    btnToAddFollowText.textContent = '+';
  } else if (style === 'follow-back') {
    btnToAddFollowText.textContent = '+ FOLLOW BACK';
  } else {
    btnToAddFollowText.textContent = '+ FOLLOW';
  }
}

function addFollowingText(butt, style) {
  var btnToAddFollowingText = butt;
  if (style === 'small') {
    btnToAddFollowingText.textContent = '✓';
  } else {
    btnToAddFollowingText.textContent = '✓ FOLLOWING';
  }
}

function assignState(butt, newState) {
  var btnToAssignState = butt;
  var style = JSON.parse(butt.dataset.info).style;
  butt.classList.add('showing');
  if (newState === 'follow' || newState === 'follow-back') {
    btnToAssignState.dataset.verb = 'unfollow';
    butt.classList.remove('following-butt');
    if (newState === 'follow-back') {
      addFollowText(butt, newState);
    } else if (newState === 'follow') {
      addFollowText(butt, style);
    }
  } else if (newState === 'login') {
    addFollowText(butt, style);
  } else if (newState === 'self') {
    btnToAssignState.dataset.verb = 'self';
    btnToAssignState.textContent = 'EDIT PROFILE';
  } else {
    btnToAssignState.dataset.verb = 'follow';
    addFollowingText(butt, style);
    butt.classList.add('following-butt');
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

function findFollowButts(fab, evFabUserId, requestVerb) {
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
    return undefined;
  }
  return undefined;
}

function handleOptimisticButtRender(butt) {
  if (butt.dataset.verb === 'self') {
    window.location.href = '/settings';
  } else if (butt.dataset.verb === 'login') {
    showModal('follow-button');
  } else {
    // Handles actual following of tags/users
    try {
      // lets try grab the event buttons info data attribute user id
      var evFabUserId = JSON.parse(butt.dataset.info).id;
      var requestVerb = butt.dataset.verb;
      // now for all follow action buttons
      document.querySelectorAll('.follow-action-button').forEach(fab => {
        findFollowButts(fab, evFabUserId, requestVerb);
      });
    } catch (err) {
      return;
    }
    handleFollowButtPress(butt);
  }
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

function addButtClickHandle(response, butt) {
  var btnToHandle = butt;
  // currently lacking error handling
  var buttInfo = JSON.parse(btnToHandle.dataset.info);
  assignInitialButtResponse(response, btnToHandle);
  btnToHandle.onclick = e => {
    e.preventDefault();
    handleOptimisticButtRender(btnToHandle);
  };
}

function handleTagButtAssignment(user, butt, buttInfo) {
  var buttAssignmentBoolean =
    JSON.parse(user.followed_tags)
      .map(a => {
        return a.id;
      })
      .indexOf(buttInfo.id) !== -1;
  var buttAssignmentBoolText = buttAssignmentBoolean ? 'true' : 'false';
  addButtClickHandle(buttAssignmentBoolText, butt);
}

function fetchButt(butt, buttInfo) {
  var btnToFetch = butt;
  btnToFetch.dataset.fetched = 'fetched';
  var dataRequester;
  if (window.XMLHttpRequest) {
    dataRequester = new XMLHttpRequest();
  } else {
    dataRequester = new window.ActiveXObject('Microsoft.XMLHTTP');
  }
  dataRequester.onreadystatechange = () => {
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

function addModalEventListener(butt) {
  var btn = butt;
  assignState(btn, 'login');
  btn.onclick = e => {
    e.preventDefault();
    showModal('follow-button');
  };
}

// private

function initializeFollowButt(butt) {
  var user = userData();
  var deviceWidth =
    window.innerWidth > 0 ? window.innerWidth : window.screen.width;
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
  }
  if (butt.dataset.fetched === 'fetched') {
    return;
  }
  fetchButt(butt, buttInfo);
}

function initializeAllFollowButts() {
  var followButts = document.getElementsByClassName('follow-action-button');
  for (var i = 0; i < followButts.length; i += 1) {
    initializeFollowButt(followButts[i]);
  }
}
