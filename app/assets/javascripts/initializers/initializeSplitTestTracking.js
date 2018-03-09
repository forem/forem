function sendSplitViewData(versionString) {
  ga('send', {
    hitType: 'event',
    eventCategory: 'Split Test',
    eventAction: 'view',
    eventLabel: 'Version: ' + versionString
  });
}

function isHidden(el) {
  return (el.offsetParent === null);
}

function initializeSplitTestTracking() {
  setTimeout(function () {
    var divs = document.getElementsByClassName('split-test-tracking-div');
    for (var i = 0; i < divs.length; i++) {
      if (typeof ga === 'function' && !isHidden(divs[i])) {
        sendSplitViewData(divs[i].dataset.version);
      }
    }
  }, 350);
}

function trackOutboundLink(url, versionString) {
  if (window.ga && ga.loaded) {
    ga('send', 'event', 'Split Test', 'signup-click', 'Version: ' + versionString, {
      'transport': 'beacon',
      'hitCallback': function () { document.location = url; }
    });
  } else {
    // Andy: send without tracking any of user's information
    window.location = url;
  }
}
