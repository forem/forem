/* global userData */
// This is currently a duplicate of app/assets/javascript/initializers/initializeBillboardVisibility.
export function initializeBillboardVisibility() {
  const billboards = document.querySelectorAll('[data-display-unit]');

  if (billboards && billboards.length == 0) {
    return;
  }

  const user = userData();

  billboards.forEach((ad) => {
    if (user && !user.display_sponsors && ad.dataset['typeOf'] == 'external') {
      ad.classList.add('hidden');
    } else {
      ad.classList.remove('hidden');
    }
  });
}

export function observeBillboards() {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const elem = entry.target;
          if (entry.intersectionRatio >= 0.25) {
            setTimeout(() => {
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
    ad.addEventListener('click', () => trackAdClick(ad));
  });
}

function trackAdImpression(adBox) {
  const isBot =
    /bot|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex/i.test(
      navigator.userAgent,
    ); // is crawler
  const adSeen = adBox.dataset.impressionRecorded;
  if (isBot || adSeen) {
    return;
  }

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  const dataBody = {
    billboard_event: {
      billboard_id: adBox.dataset.id,
      context_type: adBox.dataset.contextType,
      category: adBox.dataset.categoryImpression,
    },
  };

  window
    .fetch('/billboard_events', {
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
  const isBot =
    /bot|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex/i.test(
      navigator.userAgent,
    ); // is crawler
  const adClicked = adBox.dataset.clickRecorded;
  if (isBot || adClicked) {
    return;
  }

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  const dataBody = {
    billboard_event: {
      billboard_id: adBox.dataset.id,
      context_type: adBox.dataset.contextType,
      category: adBox.dataset.categoryClick,
    },
  };

  window.fetch('/billboard_events', {
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
