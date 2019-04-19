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
  }
}
