function initializePWAFunctionality() {
  if (window.matchMedia('(display-mode: standalone)').matches) {
    document
      .getElementById('pwa-nav-buttons')
      .classList.add('pwa-nav-buttons--showing');
    document.getElementById('app-back-button').onclick = function(e) {
      e.preventDefault();
      window.history.back();
    };
    document.getElementById('app-forward-button').onclick = function(e) {
      e.preventDefault();
      window.history.forward();
    };
    document.getElementById('app-refresh-button').onclick = function(e) {
      e.preventDefault();
      window.location.reload();
    };
    var isTouchDevice = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|DEV-Native-ios/i.test(
      navigator.userAgent,
    );
    if (!isTouchDevice) {
      var domain = window.location.protocol + '//' + window.location.host;
      var links = document.getElementsByTagName('a');
      for (var i = 0, max = links.length; i < max; i++) {
        var a = links[i];
        if (a.href.indexOf(domain + '/') === 0 || a.href.indexOf('/') === 0) {
          // Is internal link. Do nothing right now.
        } else {
          a.setAttribute('target', '_blank');
          a.setAttribute('rel', 'noopener noreferrer');
        }
      }
    }
  }
}
