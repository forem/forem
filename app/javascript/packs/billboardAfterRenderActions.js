/* global userData */
import { isBotUserAgent } from '@utilities/isBot';
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

// Billboards in a placement area configured as "hidden by default" render with
// data-placement-hidden="true" and record no impressions until revealed.
function isBillboardPlacementHidden(billboard) {
  return billboard.dataset.placementHidden === 'true';
}

// Revealed areas are remembered on #page-content so the state is shared by
// every separately bundled pack, and is forgotten when InstantClick swaps in
// the next page's content.
function revealedPlacementAreasHolder() {
  return document.getElementById('page-content') || document.body;
}

function revealedPlacementAreas() {
  const areas =
    revealedPlacementAreasHolder().dataset.revealedBillboardPlacements;
  return areas ? areas.split(' ') : [];
}

function revealPendingBillboardPlacements() {
  const areas = revealedPlacementAreas();
  const revealed = [];
  if (areas.length === 0) {
    return revealed;
  }

  document
    .querySelectorAll('[data-display-unit][data-placement-hidden="true"]')
    .forEach((billboard) => {
      if (areas.includes(billboard.dataset.placementArea)) {
        billboard.dataset.placementHidden = 'false';
        revealed.push(billboard);
      }
    });
  return revealed;
}

/**
 * Reveals billboards in a placement area configured as "hidden by default",
 * including ones that finish loading after this call. A revealed billboard
 * records its impression once it is actually in view, like any other billboard.
 * Exposed as window.Forem.revealBillboardPlacement.
 *
 * @param {string} placementArea The placement area to reveal, e.g. "post_sidebar"
 */
export function revealBillboardPlacement(placementArea) {
  if (!placementArea) {
    return;
  }

  const areas = revealedPlacementAreas();
  if (!areas.includes(placementArea)) {
    revealedPlacementAreasHolder().dataset.revealedBillboardPlacements = [
      ...areas,
      placementArea,
    ].join(' ');
  }

  // A fresh observer always reports the current intersection, so a revealed
  // billboard that is already on screen counts without needing to scroll.
  const observer = createImpressionObserver();
  revealPendingBillboardPlacements().forEach((billboard) =>
    observer.observe(billboard),
  );
}

function createImpressionObserver() {
  return new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const elem = entry.target;
        if (entry.isIntersecting && entry.intersectionRatio >= 0.25) {
          elem.dataset.isBillboardVisible = 'true';
          setTimeout(() => {
            if (
              elem.dataset.isBillboardVisible === 'true' &&
              !isBillboardPlacementHidden(elem)
            ) {
              trackAdImpression(elem);
              startPollingBillboard(elem);
            }
          }, 200);
        } else {
          elem.dataset.isBillboardVisible = 'false';
          const intervalId = elem.dataset.pollingIntervalId;
          if (intervalId) {
            clearInterval(Number(intervalId));
            elem.removeAttribute('data-polling-interval-id');
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
}

export function observeBillboards() {
  // Billboards render asynchronously, so one may arrive after its placement
  // area was already revealed on this page.
  revealPendingBillboardPlacements();

  const observer = createImpressionObserver();
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
  const isBot = isBotUserAgent(navigator.userAgent);
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
    .then((response) => {
      if (response && response.ok && typeof response.json === 'function') {
        return response.json();
      }
    })
    .then((data) => {
      if (data && data.id) {
        adBox.dataset.eventId = data.id;
      }
    })
    .catch((error) => console.error(error));

  adBox.dataset.impressionRecorded = true;
}

function updateBillboardImpressionTime(adBox) {
  const eventId = adBox.dataset.eventId;
  if (!eventId) {
    return;
  }

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  window.fetch(`/bb_tabulations/${eventId}`, {
    method: 'PATCH',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  }).catch((error) => console.error(error));
}

function startPollingBillboard(adBox) {
  if (adBox.dataset.pollingIntervalId) {
    return; // Already polling
  }

  const intervalId = setInterval(() => {
    if (document.visibilityState === 'visible' && adBox.dataset.isBillboardVisible === 'true') {
      updateBillboardImpressionTime(adBox);
    }
  }, 10000);

  adBox.dataset.pollingIntervalId = intervalId;
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

  const isBot = isBotUserAgent(navigator.userAgent);
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
