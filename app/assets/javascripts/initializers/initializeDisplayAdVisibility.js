function initializeDisplayAdVisibility() {
  var displayAds = document.querySelectorAll('[data-display-unit]');

  if (displayAds && displayAds.length == 0) {
    return;
  }

  var user = userData();

  displayAds.forEach((ad) => {
    if (user && !user.display_sponsors && ad.dataset['typeOf'] == 'external') {
      ad.classList.add('hidden');
    } else {
      ad.classList.remove('hidden');
    }
  });
}

function trackAdImpression(adBox) {
  var isBot = /bot|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex/i.test(
    navigator.userAgent,
  ); // is crawler
  var adSeen = adBox.dataset.impressionRecorded;
  if (isBot || adSeen) {
    return;
  }

  var tokenMeta = document.querySelector("meta[name='csrf-token']");
  var csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  var dataBody = {
    display_ad_event: {
      display_ad_id: adBox.dataset.id,
      context_type: adBox.dataset.contextType,
      category: adBox.dataset.categoryImpression,
    },
  };

  window
    .fetch('/display_ad_events', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(dataBody),
      credentials: 'same-origin',
    })
    .catch((error) => console.error(error));

  adBox.dataset.impressionRecorded = true;
}

function trackAdClick(adBox) {
  var isBot = /bot|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex/i.test(
    navigator.userAgent,
  ); // is crawler
  var adClicked = adBox.dataset.clickRecorded;
  if (isBot || adClicked) {
    return;
  }

  var tokenMeta = document.querySelector("meta[name='csrf-token']");
  var csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  var dataBody = {
    display_ad_event: {
      display_ad_id: adBox.dataset.id,
      context_type: adBox.dataset.contextType,
      category: adBox.dataset.categoryClick,
    },
  };
  window.fetch('/display_ad_events', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(dataBody),
    credentials: 'same-origin',
  });

  adBox.dataset.clickRecorded = true;
}

function observeDisplayAds() {
  let observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          let elem = entry.target;

          if (entry.intersectionRatio >= 0.25) {
            setTimeout(function () {
              trackAdImpression(elem);
            }, 1);
          }
        }
      });
    },
    {
      root: null, // defaults to browser viewport
      rootMargin: '0px',
      threshold: 0.25,
    },
  );

  document.querySelectorAll('[data-display-unit]').forEach((ad) => {
    observer.observe(ad);
    ad.removeEventListener('click', trackAdClick, false);
    ad.addEventListener('click', function (e) {
      trackAdClick(ad);
    });
  });
}

window.addEventListener(
  'load',
  (event) => {
    // This timeout is a patch to fix a race condition now that we load these elements async
    // A MutationObserver or similar would be a better solution, as this is still subject to race conditions.
    // However, since we may have differing logic as far as how many units we load, some async, some not, this patch
    // seems like a sufficient solution for mitigation, but should be revisited in the future.
    // Better approaches welcome!
    setTimeout(function () {
      observeDisplayAds();
    }, 300);
  },
  false,
);
