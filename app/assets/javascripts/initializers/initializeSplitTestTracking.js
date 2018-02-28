function initializeSplitTestTracking() {
  setTimeout(function(){
    var divs =   document.getElementsByClassName("split-test-tracking-div");
    for(var i = 0; i < divs.length; i++)
    {
      if ( typeof ga === "function" && !isHidden(divs[i]) ) {
        sendSplitViewData(divs[i].dataset.version);
      }
    }
  },350)
}

function isHidden(el) {
    return (el.offsetParent === null)
}

function trackOutboundLink(url,versionString) {
   ga('send', 'event', 'Split Test', 'signup-click', 'Version: '+versionString, {
     'transport': 'beacon',
     'hitCallback': function(){document.location = url;}
   });
}

function sendSplitViewData(versionString) {
  ga('send', {
    hitType: 'event',
    eventCategory: 'Split Test',
    eventAction: 'view',
    eventLabel: 'Version: '+ versionString
  });
}