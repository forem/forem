/* global showLoginModal */

function initializeAllFollowButts() {
  var followButts = document.getElementsByClassName('follow-action-button');
  for (var i = 0; i < followButts.length; i++) {
    if (!followButts[i].className.includes('follow-user')) {
      initializeFollowButt(followButts[i]);
    }
  }
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
      addButtClickHandles(dataRequester.response, [butt]);
    }
  };
  dataRequester.open(
    'GET',
    '/follows/' + buttInfo.id + '?followable_type=' + buttInfo.className,
    true,
  );
  dataRequester.send();
}

function addButtClickHandles(response, buttons) {
  // currently lacking error handling
  buttons.forEach((butt) => {
    assignInitialButtResponse(response, butt);
    butt.dataset.clickInitialized = 'true';
  });
}

function handleTagButtAssignment(user, butt, buttInfo) {
  var buttAssignmentBoolean =
    JSON.parse(user.followed_tags)
      .map(function (a) {
        return a.id;
      })
      .indexOf(buttInfo.id) !== -1;

  var buttAssignmentBoolText = buttAssignmentBoolean ? 'true' : 'false';
  addButtClickHandles(buttAssignmentBoolText, [butt]);
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

function assignState(butt, newState) {
  // var style = JSON.parse(butt.dataset.info).style;
  // var followStyle = JSON.parse(butt.dataset.info).followStyle;
  // butt.classList.add('showing');
  // if (newState === 'follow' || newState === 'follow-back') {
  //   butt.dataset.verb = 'unfollow';
  //   butt.classList.remove('crayons-btn--outlined');
  //   if (followStyle === 'primary') {
  //     butt.classList.add('crayons-btn--primary');
  //   } else if (followStyle === 'secondary') {
  //     butt.classList.add('crayons-btn--secondary');
  //   }
  //   if (newState === 'follow-back') {
  //     addFollowText(butt, newState);
  //   } else if (newState === 'follow') {
  //     addFollowText(butt, style);
  //   }
  // } else if (newState === 'login') {
  //   addFollowText(butt, style);
  // } else if (newState === 'self') {
  //   butt.dataset.verb = 'self';
  //   butt.textContent = 'Edit profile';
  // } else {
  //   butt.dataset.verb = 'follow';
  //   addFollowingText(butt, style);
  //   butt.classList.remove('crayons-btn--primary');
  //   butt.classList.remove('crayons-btn--secondary');
  //   butt.classList.add('crayons-btn--outlined');
  // }
}
