/*
 * kept as a stand function so it can be loaded again without issue
 * see: https://github.com/forem/forem/issues/6468
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

function sponsorClickHandlerGA4(event) {
  gtag('event', 'click sponsor link', {
    event_category: 'click',
    event_label: event.target.dataset.details,
  });
}

function listenForSponsorClick() {
  setTimeout(() => {
    if (window.ga || window.gtag) {
      var links = document.getElementsByClassName('partner-link');
      // eslint-disable-next-line no-plusplus
      for (var i = 0; i < links.length; i++) {
        if (window.ga) {
          links[i].onclick = sponsorClickHandler;
        }
        if (window.gtag) {
          links[i].onclick = sponsorClickHandlerGA4;
        }
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
      if (document.querySelectorAll('[data-partner-seen]').length === 0) {
        if (window.ga) {
          ga(
            'send',
            'event',
            'view',
            'sponsor displayed on page',
            el.dataset.details,
            null,
          );
        }
        if (window.gtag) {
          gtag('event', 'sponsor displayed on page', {
            event_category: 'view',
            event_label: el.dataset.details,
          });
        }
        el.dataset.partnerSeen = 'true';
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
