// GitHub-style activity heatmap, rendered via ApexCharts.
//
// The dashboard analytics page already uses ApexCharts for every other
// time-series visual (see app/javascript/analytics/dashboard.js), so the
// heatmap follows the same lazy-import / activeCharts-registry pattern.
//
// Series layout: 7 series (one per weekday, Sun..Sat top-to-bottom).
// Each series.data is one entry per calendar week, with `x` set to the ISO
// date of that week's Sunday so the x-axis formatter can label month
// boundaries.
//
// Color buckets are derived from `payload.max` so a quiet user still sees
// gradation. Detail breakdown (articles / comments / reactions) is shown
// via a custom tooltip — replacing the older sidebar detail panel.

const DAY_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTH_LABELS = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// Module-scope registry of rendered charts keyed by container id so a
// re-render (year-picker change, InstantClick re-init) can destroy the
// previous instance before mounting a new one.
const activeCharts = {};

// Track the currently-rendered instance so a single document-level Esc
// listener can clear the pin without leaking one new listener per render.
let activeInstance = null;
let keydownAttached = false;

function ensureKeydownListener() {
  if (keydownAttached) return;
  keydownAttached = true;
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && activeInstance && activeInstance.pinnedDate) {
      activeInstance.clearPin();
    }
  });
}

function isDarkMode() {
  return document.body.classList.contains('dark-theme');
}

function parseIso(iso) {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

function formatDate(iso) {
  const date = parseIso(iso);
  return `${DAY_LABELS[date.getUTCDay()]} ${MONTH_LABELS[date.getUTCMonth()]} ${date.getUTCDate()}, ${date.getUTCFullYear()}`;
}

function pluralize(count, singular, plural) {
  return count === 1 ? singular : plural;
}

function computeStreaks(days) {
  let longest = 0;
  let run = 0;
  for (let i = 0; i < days.length; i += 1) {
    if (days[i].total > 0) {
      run += 1;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }
  let current = 0;
  for (let i = days.length - 1; i >= 0; i -= 1) {
    if (days[i].total > 0) current += 1;
    else break;
  }
  return { current, longest };
}

function findBestDay(days) {
  let best = null;
  for (let i = 0; i < days.length; i += 1) {
    if (!best || days[i].total > best.total) best = days[i];
  }
  return best;
}

function renderStats(statsEl, days, totals, labels) {
  if (!statsEl) return;

  const { current, longest } = computeStreaks(days);
  const best = findBestDay(days);
  const total = (totals && totals.total) || 0;

  statsEl.innerHTML = '';
  const items = [
    {
      label: labels.totalLabel,
      value: total.toLocaleString(),
      sub: `${(totals && totals.articles) || 0} ${labels.articlesLabel.toLowerCase()} · ${(totals && totals.comments) || 0} ${labels.commentsLabel.toLowerCase()} · ${(totals && totals.reactions) || 0} ${labels.reactionsLabel.toLowerCase()}`,
    },
    {
      label: labels.currentStreakLabel,
      value: current,
      sub: `${current} ${pluralize(current, labels.dayLabel, labels.daysLabel)}`,
    },
    {
      label: labels.longestStreakLabel,
      value: longest,
      sub: `${longest} ${pluralize(longest, labels.dayLabel, labels.daysLabel)}`,
    },
    {
      label: labels.bestDayLabel,
      value: best && best.total > 0 ? best.total : 0,
      sub: best && best.total > 0 ? formatDate(best.date) : labels.noActivityLabel,
    },
  ];

  items.forEach((item) => {
    const card = document.createElement('div');
    card.className = 'heatmap-stat';
    const v = document.createElement('div');
    v.className = 'heatmap-stat__value';
    v.textContent = item.value;
    const l = document.createElement('div');
    l.className = 'heatmap-stat__label';
    l.textContent = item.label;
    const s = document.createElement('div');
    s.className = 'heatmap-stat__sub';
    s.textContent = item.sub;
    card.appendChild(v);
    card.appendChild(l);
    card.appendChild(s);
    statsEl.appendChild(card);
  });
}

// Pack the linear `days` array into a 7-row × N-column grid aligned to
// calendar weeks. Row index 0 is Sunday so ApexCharts (which renders the
// first series at the top) produces a GitHub-style Sun..Sat layout.
//
// Returns { series, dayLookup } where dayLookup is a {row}-{col} -> day map
// the tooltip uses to access the original day record without round-tripping
// through ApexCharts' data point representation.
function buildSeries(days) {
  if (!days.length) return { series: [], dayLookup: {} };

  const firstDate = parseIso(days[0].date);
  const firstDow = firstDate.getUTCDay();

  const dayLookup = {};
  let maxCol = 0;
  days.forEach((day, i) => {
    const cell = i + firstDow;
    const row = cell % 7;
    const col = Math.floor(cell / 7);
    dayLookup[`${row}-${col}`] = day;
    if (col > maxCol) maxCol = col;
  });
  const columnCount = maxCol + 1;

  // Sunday on/before the first observed day — used to label each column
  // with the ISO date of its starting Sunday.
  const anchor = new Date(firstDate.getTime());
  anchor.setUTCDate(anchor.getUTCDate() - firstDow);

  const xLabels = [];
  for (let c = 0; c < columnCount; c += 1) {
    const wkStart = new Date(anchor.getTime());
    wkStart.setUTCDate(anchor.getUTCDate() + c * 7);
    xLabels.push(wkStart.toISOString().slice(0, 10));
  }

  const series = [];
  for (let row = 0; row < 7; row += 1) {
    const data = [];
    for (let col = 0; col < columnCount; col += 1) {
      const day = dayLookup[`${row}-${col}`] || null;
      data.push({ x: xLabels[col], y: day ? day.total : 0 });
    }
    series.push({ name: DAY_LABELS[row], data });
  }

  return { series, dayLookup, xLabels };
}

// Discrete color ramp keyed off `payload.max`. ApexCharts' `colorScale`
// switches color when y >= `from`, so half-open boundaries (`-0.5`, `0.5`)
// keep integer totals from straddling buckets.
function colorRanges(max) {
  const empty = isDarkMode() ? '#1f2937' : '#ebedf0';
  const colors = ['#9be9a8', '#40c463', '#30a14e', '#216e39'];

  if (max <= 0) {
    return [{ from: -0.5, to: 0.5, color: empty, name: '0' }];
  }
  if (max === 1) {
    return [
      { from: -0.5, to: 0.5, color: empty, name: '0' },
      { from: 0.5, to: 1.5, color: colors[3], name: '1' },
    ];
  }

  const q1 = Math.max(1, Math.round(max * 0.25));
  const q2 = Math.max(q1 + 1, Math.round(max * 0.5));
  const q3 = Math.max(q2 + 1, Math.round(max * 0.75));

  return [
    { from: -0.5, to: 0.5, color: empty, name: '0' },
    { from: 0.5, to: q1 + 0.5, color: colors[0], name: `1-${q1}` },
    { from: q1 + 0.5, to: q2 + 0.5, color: colors[1], name: `${q1 + 1}-${q2}` },
    { from: q2 + 0.5, to: q3 + 0.5, color: colors[2], name: `${q2 + 1}-${q3}` },
    { from: q3 + 0.5, to: max + 0.5, color: colors[3], name: `${q3 + 1}+` },
  ];
}

function escapeHtml(str) {
  return String(str).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

function tooltipHTML(day, labels) {
  if (!day) {
    return `<div class="heatmap-tooltip"><div class="heatmap-tooltip__title">${escapeHtml(labels.noActivityLabel)}</div></div>`;
  }
  const title = escapeHtml(formatDate(day.date));
  const totalCount = day.total || 0;
  const totalText = `${totalCount} ${pluralize(totalCount, labels.contributionLabel, labels.contributionsLabel)}`;
  return [
    '<div class="heatmap-tooltip">',
    `<div class="heatmap-tooltip__title">${title}</div>`,
    `<div class="heatmap-tooltip__total">${escapeHtml(totalText)}</div>`,
    '<ul class="heatmap-tooltip__list">',
    `<li><span>${escapeHtml(labels.articlesLabel)}</span><span>${day.articles || 0}</span></li>`,
    `<li><span>${escapeHtml(labels.commentsLabel)}</span><span>${day.comments || 0}</span></li>`,
    `<li><span>${escapeHtml(labels.reactionsLabel)}</span><span>${day.reactions || 0}</span></li>`,
    '</ul>',
    '</div>',
  ].join('');
}

// Render the persistent side panel. `pinned` controls the data-attribute
// hook that styling/tests can key off; the visible UI is identical so the
// panel stays uncluttered (clicking a cell or hitting Esc is self-evident).
function renderDetail(panelEl, day, labels, pinned) {
  if (!panelEl) return;
  panelEl.innerHTML = '';
  panelEl.dataset.pinned = pinned ? 'true' : 'false';

  if (!day) {
    const hint = document.createElement('p');
    hint.className = 'heatmap-detail__hint';
    hint.textContent = labels.detailHintLabel;
    panelEl.appendChild(hint);
    return;
  }

  const header = document.createElement('div');
  header.className = 'heatmap-detail__header';
  const title = document.createElement('h3');
  title.className = 'heatmap-detail__title';
  title.textContent = formatDate(day.date);
  header.appendChild(title);
  panelEl.appendChild(header);

  const totalCount = day.total || 0;
  const total = document.createElement('p');
  total.className = 'heatmap-detail__total';
  total.textContent = `${totalCount} ${pluralize(totalCount, labels.contributionLabel, labels.contributionsLabel)}`;
  panelEl.appendChild(total);

  const list = document.createElement('ul');
  list.className = 'heatmap-detail__list';
  [
    { label: labels.articlesLabel, value: day.articles || 0 },
    { label: labels.commentsLabel, value: day.comments || 0 },
    { label: labels.reactionsLabel, value: day.reactions || 0 },
  ].forEach((row) => {
    const li = document.createElement('li');
    li.className = 'heatmap-detail__row';
    const k = document.createElement('span');
    k.className = 'heatmap-detail__key';
    k.textContent = row.label;
    const v = document.createElement('span');
    v.className = 'heatmap-detail__value';
    v.textContent = row.value;
    li.appendChild(k);
    li.appendChild(v);
    list.appendChild(li);
  });
  panelEl.appendChild(list);
}

function buildChartOptions(payload, labels, dayLookup, series, xLabels, onSelect) {
  const max = (payload && payload.max) || 0;
  return {
    chart: {
      type: 'heatmap',
      height: 240,
      toolbar: { show: false },
      animations: { enabled: false },
      fontFamily: 'inherit',
      // Let the chart panel’s background show through instead of the
      // ApexCharts default so the chart wrapper looks like one solid
      // surface flush with the side panel.
      background: 'transparent',
      // ApexCharts' keyboard-navigation a11y feature paints a blue stroke
      // on the initially-focused heatmap rect (data point 0,0, which is
      // the bottom-left cell because Sun is series index 0). We do not
      // expose keyboard-driven cell traversal anyway — pinning happens
      // via the side panel and Esc — so disable that subsystem.
      accessibility: {
        keyboard: { enabled: false },
      },
      events: {
        // Use the plain click event instead of `dataPointSelection` so
        // ApexCharts does not promote the clicked rect to its internal
        // "selected" state (which paints a blue outline on data point 0,0).
        click: (_event, _ctx, config) => {
          if (!onSelect) return;
          if (config.seriesIndex == null || config.dataPointIndex == null) return;
          if (config.seriesIndex < 0 || config.dataPointIndex < 0) return;
          const day = dayLookup[`${config.seriesIndex}-${config.dataPointIndex}`];
          if (day) onSelect(day);
        },
      },
    },
    series,
    plotOptions: {
      heatmap: {
        radius: 2,
        enableShades: false,
        colorScale: { ranges: colorRanges(max) },
      },
    },
    // Suppress ApexCharts' default "active" selection highlight (a blue
    // outline on the picked cell, which also bleeds onto a stray default
    // data-point) — pinning is communicated via the side panel instead.
    states: {
      hover: { filter: { type: 'lighten', value: 0.1 } },
      active: { allowMultipleDataPointsSelection: false, filter: { type: 'none' } },
    },
    dataLabels: { enabled: false },
    stroke: {
      width: 1,
      colors: [isDarkMode() ? '#0b0d10' : '#ffffff'],
    },
    // Leave room on the left so the Sun..Sat row labels aren't clipped.
    grid: { padding: { left: 8, right: 0, top: 0, bottom: 0 } },
    legend: { show: false },
    theme: { mode: isDarkMode() ? 'dark' : 'light' },
    xaxis: {
      type: 'category',
      categories: xLabels,
      labels: {
        rotate: 0,
        hideOverlappingLabels: true,
        // Show a month label only on the column that contains the first of
        // the month, so the axis reads like a calendar without overcrowding.
        formatter: (val) => {
          if (!val || typeof val !== 'string') return '';
          const d = parseIso(val);
          if (Number.isNaN(d.getTime())) return '';
          if (d.getUTCDate() <= 7) return MONTH_LABELS[d.getUTCMonth()];
          return '';
        },
        style: { fontSize: '11px' },
      },
      axisBorder: { show: false },
      axisTicks: { show: false },
      tooltip: { enabled: false },
    },
    yaxis: {
      labels: {
        style: { fontSize: '11px' },
        minWidth: 28,
      },
      axisBorder: { show: false },
      axisTicks: { show: false },
    },
    tooltip: {
      custom: ({ seriesIndex, dataPointIndex }) => {
        const day = dayLookup[`${seriesIndex}-${dataPointIndex}`];
        return tooltipHTML(day, labels);
      },
    },
  };
}

export function renderHeatmap(rootEl, payload, options = {}) {
  if (!rootEl) return;

  const labels = {
    emptyLabel: options.emptyLabel || 'No activity yet.',
    totalLabel: options.totalLabel || 'Total',
    currentStreakLabel: options.currentStreakLabel || 'Current streak',
    longestStreakLabel: options.longestStreakLabel || 'Longest streak',
    bestDayLabel: options.bestDayLabel || 'Best day',
    dayLabel: options.dayLabel || 'day',
    daysLabel: options.daysLabel || 'days',
    articlesLabel: options.articlesLabel || 'Articles',
    commentsLabel: options.commentsLabel || 'Comments',
    reactionsLabel: options.reactionsLabel || 'Reactions',
    contributionLabel: options.contributionLabel || 'contribution',
    contributionsLabel: options.contributionsLabel || 'contributions',
    noActivityLabel: options.noActivityLabel || 'No activity yet',
    detailHintLabel: options.detailHintLabel || 'Click any day to pin the breakdown.',
  };

  const wrapper = options.wrapperEl || rootEl.parentElement || rootEl;
  const statsEl = wrapper.querySelector('[data-heatmap-stats]');
  const panelEl = wrapper.querySelector('[data-heatmap-detail]');

  const days = (payload && payload.days) || [];
  renderStats(statsEl, days, payload && payload.totals, labels);

  // Tear down any previous chart bound to this container before re-mounting.
  const chartKey = rootEl.id || '__heatmap__';
  if (activeCharts[chartKey]) {
    activeCharts[chartKey].destroy();
    delete activeCharts[chartKey];
  }
  rootEl.innerHTML = '';

  if (days.length === 0) {
    const empty = document.createElement('p');
    empty.className = 'heatmap__empty';
    empty.textContent = labels.emptyLabel;
    rootEl.appendChild(empty);
    renderDetail(panelEl, null, labels, false);
    return;
  }

  const { series, dayLookup, xLabels } = buildSeries(days);

  // Per-render instance with the pin state. Closing over panelEl/labels
  // keeps the Esc-listener dispatch tidy via module-scope activeInstance.
  const instance = {
    pinnedDate: null,
    clearPin() {
      this.pinnedDate = null;
      const best = findBestDay(days);
      if (best && best.total > 0) renderDetail(panelEl, best, labels, false);
      else renderDetail(panelEl, null, labels, false);
    },
  };
  activeInstance = instance;
  ensureKeydownListener();

  const onSelect = (day) => {
    // Clicking the already-pinned cell clears the pin; otherwise the new
    // cell becomes the sticky selection.
    if (instance.pinnedDate === day.date) {
      instance.clearPin();
      return;
    }
    instance.pinnedDate = day.date;
    renderDetail(panelEl, day, labels, true);
  };

  // Seed the side panel: show the best day as a default sticky view so
  // users see something meaningful before they click.
  const best = findBestDay(days);
  if (best && best.total > 0) renderDetail(panelEl, best, labels, false);
  else renderDetail(panelEl, null, labels, false);

  const opts = buildChartOptions(payload, labels, dayLookup, series, xLabels, onSelect);

  import('apexcharts').then(({ default: ApexCharts }) => {
    // A second render may have superseded us while the dynamic import was
    // in flight; bail if the container has been torn down.
    if (!rootEl.isConnected) return;
    if (activeCharts[chartKey]) {
      activeCharts[chartKey].destroy();
      delete activeCharts[chartKey];
    }
    const chart = new ApexCharts(rootEl, opts);
    activeCharts[chartKey] = chart;
    chart.render();
  });
}

// Exported for unit tests so we can exercise the pure helpers without
// stubbing the ApexCharts side of `renderHeatmap`.
export const __testing__ = {
  buildSeries,
  colorRanges,
  computeStreaks,
  findBestDay,
  tooltipHTML,
  renderDetail,
};
