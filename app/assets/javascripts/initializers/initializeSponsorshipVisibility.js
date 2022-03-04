/*
 * kept as a stand function so it can be loaded again without issue
 * see: https://github.com/thepracticaldev/dev.to/issues/6468
 */
function sponsorClickHandler(event) {
  ga(
    'send',
    'event',
    'click',
    'click sponsor link',
    event.target.dataset.details,
    null,
  );
}

function listenForSponsorClick() {
  setTimeout(() => {
    if (window.ga) {
      var links = document.getElementsByClassName('partner-link');
      // eslint-disable-next-line no-plusplus
      for (var i = 0; i < links.length; i++) {
        links[i].onclick = sponsorClickHandler;
      }
    }
  }, 400);
}

function initializeSponsorshipVisibility() {
  var el =
    document.getElementById('sponsorship-widget') ||
    document.getElementById('partner-content-display');
  var user = userData();
  if (el) {
    setTimeout(() => {
      if (window.ga) {
        if (document.querySelectorAll('[data-partner-seen]').length === 0) {
          ga(
            'send',
            'event',
            'view',
            'sponsor displayed on page',
            el.dataset.details,
            null,
          );
          el.dataset.partnerSeen = 'true';
        }
      }
    }, 400);
  }
  if (el && user && user.display_sponsors) {
    el.classList.remove('hidden');
    listenForSponsorClick();
  } else if (el && user) {
    el.classList.add('hidden');
  } else if (el) {
    el.classList.remove('hidden');
    listenForSponsorClick();
  }
}
