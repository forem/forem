function initializeDisplayAdVisibility() {
  var displayAds = document.querySelectorAll('[data-display-unit]');

  if (displayAds && displayAds.length == 0) {
    return;
  }

  var user = userData();

  displayAds.forEach((ad) => {
    if (user && !user.display_sponsors) {
      ad.classList.add('hidden');
    } else {
      ad.classList.remove('hidden');
    }
  });

  // for impression & click-tracking, see initializeBaseTracking
}
