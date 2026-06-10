// Entry pack for the user-activity heatmap on /dashboard/analytics.
// Auto-discovered by esbuild.config.mjs because it lives under packs/.

import { renderHeatmap } from '../dashboardHeatmap/heatmap';

function fetchPayload(endDate) {
  const url = endDate
    ? `/api/analytics/heatmap?end=${encodeURIComponent(endDate)}`
    : '/api/analytics/heatmap';
  return fetch(url, {
    method: 'GET',
    credentials: 'same-origin',
    headers: {
      Accept: 'application/vnd.forem.api-v1+json',
    },
  }).then((response) => {
    if (!response.ok) throw new Error(`Heatmap request failed: ${response.status}`);
    return response.json();
  });
}

function updateSubtitle(wrapperEl, payload, year) {
  const subtitleEl = wrapperEl.querySelector('[data-heatmap-subtitle]');
  if (!subtitleEl) return;
  const total = (payload && payload.totals && payload.totals.total) || 0;
  const count = total.toLocaleString();
  let text;
  if (year) {
    const template = subtitleEl.dataset.templateYear || '__COUNT__ contributions in __YEAR__';
    text = template.replace('__COUNT__', count).replace('__YEAR__', year);
  } else {
    const template = subtitleEl.dataset.templateRolling || '__COUNT__ contributions in the last year';
    text = template.replace('__COUNT__', count);
  }
  subtitleEl.textContent = text;
}

function buildLabels(rootEl) {
  const d = rootEl.dataset;
  return {
    emptyLabel: d.emptyLabel,
    totalLabel: d.totalLabel,
    currentStreakLabel: d.currentStreakLabel,
    longestStreakLabel: d.longestStreakLabel,
    bestDayLabel: d.bestDayLabel,
    dayLabel: d.dayLabel,
    daysLabel: d.daysLabel,
    articlesLabel: d.articlesLabel,
    commentsLabel: d.commentsLabel,
    reactionsLabel: d.reactionsLabel,
    contributionLabel: d.contributionLabel,
    contributionsLabel: d.contributionsLabel,
    noActivityLabel: d.noActivityLabel,
    detailHintLabel: d.detailHintLabel,
  };
}

function renderInto(wrapperEl, rootEl, payload, year) {
  updateSubtitle(wrapperEl, payload, year);
  renderHeatmap(rootEl, payload, { ...buildLabels(rootEl), wrapperEl });
}

function showError(wrapperEl, rootEl) {
  const subtitleEl = wrapperEl.querySelector('[data-heatmap-subtitle]');
  if (subtitleEl) subtitleEl.textContent = rootEl.dataset.errorLabel || 'Could not load activity.';
  rootEl.innerHTML = '';
  const err = document.createElement('p');
  err.className = 'heatmap__empty';
  err.textContent = rootEl.dataset.errorLabel || 'Could not load activity.';
  rootEl.appendChild(err);
}

// Map a year-picker selection to the `end` query param the API expects.
// Blank → rolling 365 days ending today (no param).
// Current year → also rolling (no param) so the latest activity shows.
// Past year → Dec 31 of that year (server clamps future dates).
function endDateForYear(year) {
  if (!year) return null;
  const numeric = Number(year);
  if (!Number.isFinite(numeric)) return null;
  const currentYear = new Date().getUTCFullYear();
  if (numeric >= currentYear) return null;
  return `${numeric}-12-31`;
}

function load(wrapperEl, rootEl, year) {
  // Per-instance loading guard so an in-flight request can't race a newer
  // selection and stomp the displayed payload.
  const requestId = (rootEl._heatmapRequestId || 0) + 1;
  rootEl._heatmapRequestId = requestId;

  wrapperEl.classList.add('is-loading');

  const endDate = endDateForYear(year);
  fetchPayload(endDate)
    .then((payload) => {
      if (rootEl._heatmapRequestId !== requestId) return; // superseded
      rootEl._heatmapPayload = payload;
      renderInto(wrapperEl, rootEl, payload, endDate ? Number(year) : null);
      wrapperEl.classList.remove('is-loading');
    })
    .catch(() => {
      if (rootEl._heatmapRequestId !== requestId) return;
      showError(wrapperEl, rootEl);
      wrapperEl.classList.remove('is-loading');
    });
}

function initHeatmap() {
  const wrapperEl = document.querySelector('.dashboard-heatmap');
  const rootEl = document.getElementById('dashboard-heatmap');
  if (!wrapperEl || !rootEl) return;

  // Wire the year picker exactly once per DOM mount. After an InstantClick
  // navigation the wrapper is a new node so the flag is fresh.
  if (!wrapperEl._heatmapWired) {
    wrapperEl._heatmapWired = true;
    const picker = wrapperEl.querySelector('[data-heatmap-year]');
    if (picker) {
      picker.addEventListener('change', (event) => {
        load(wrapperEl, rootEl, event.target.value);
      });
    }
  }

  const picker = wrapperEl.querySelector('[data-heatmap-year]');
  const initialYear = picker ? picker.value : '';
  load(wrapperEl, rootEl, initialYear);
}

// InstantClick navigates without reloading. Re-init on page swaps.
if (window.InstantClick && !window._heatmapChangeRegistered) {
  window._heatmapChangeRegistered = true;
  window.InstantClick.on('change', () => {
    initHeatmap();
  });
}

initHeatmap();
