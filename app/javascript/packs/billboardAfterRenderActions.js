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

export function executeBBScripts(el) {
  const scriptElements = el.getElementsByTagName('script');
  let originalElement, copyElement, parentNode, nextSibling, i;

  for (i = 0; i < scriptElements.length; i++) {
    originalElement = scriptElements[i];
    if (!originalElement) {
      continue;
    }
    copyElement = document.createElement('script');
    for (let j = 0; j < originalElement.attributes.length; j++) {
      copyElement.setAttribute(
        originalElement.attributes[j].name,
        originalElement.attributes[j].value,
      );
    }
    copyElement.textContent = originalElement.textContent;
    parentNode = originalElement.parentNode;
    nextSibling = originalElement.nextSibling;
    parentNode.removeChild(originalElement);
    parentNode.insertBefore(copyElement, nextSibling);
  }
}

export function implementSpecialBehavior(element) {
  if (
    element.querySelector('.js-billboard') &&
    element.querySelector('.js-billboard').dataset.special === 'delayed'
  ) {
    element.classList.add('hidden');
    setTimeout(() => {
      showDelayed();
    }, 10000);
  }
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
            }, 200);
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
    const currentPath = window.location.pathname;
    observer.observe(ad);
    ad.removeEventListener('click', trackAdClick, false);
    ad.addEventListener('click', () => trackAdClick(ad, event, currentPath));
  });
}

function showDelayed() {
  document.querySelectorAll("[data-special='delayed']").forEach((el) => {
    el.closest('.hidden').classList.remove('hidden');
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
      article_id: adBox.dataset.articleId,
    },
  };

  window
    .fetch('/bb_tabulations', {
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

function trackAdClick(adBox, event, currentPath) {
  if (!event.target.closest("a")) {
    return;
  }

  const dataBody = {
    billboard_event: {
      billboard_id: adBox.dataset.id,
      context_type: adBox.dataset.contextType,
      category: adBox.dataset.categoryClick,
      article_id: adBox.dataset.articleId,
    },
  };

  // Check if the current click is a duplicate
  if (localStorage) {
    let lastClicked = localStorage.getItem("last_interacted_billboard");
    if (lastClicked) {
      try {
        const lastData = JSON.parse(lastClicked);
        if (
          lastData.billboard_event &&
          lastData.billboard_event.billboard_id === dataBody.billboard_event.billboard_id &&
          lastData.path === currentPath
        ) {
          // The current click is the same as the last stored one, so exit early.
          return;
        }
      } catch (error) {
        // If parsing fails, ignore and proceed.
      }
    }
    // Enrich the dataBody and update localStorage
    dataBody.path = currentPath;
    dataBody.time = new Date();
    localStorage.setItem("last_interacted_billboard", JSON.stringify(dataBody));
  }

  const isBot = /bot|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex/i.test(
    navigator.userAgent
  );
  const adClicked = adBox.dataset.clickRecorded;
  if (isBot || adClicked) {
    return;
  }

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta && tokenMeta.getAttribute("content");

  window.fetch("/bb_tabulations", {
    method: "POST",
    headers: {
      "X-CSRF-Token": csrfToken,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(dataBody),
    credentials: "same-origin",
  });

  adBox.dataset.clickRecorded = true;
}
