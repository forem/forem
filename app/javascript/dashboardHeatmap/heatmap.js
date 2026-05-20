// GitHub-style activity heatmap renderer.
//
// Builds a grid: 53 columns × 7 rows (Sun..Sat). Cells are positioned by
// week-of-year columns and day-of-week rows. Empty leading cells are still
// rendered so the grid stays visually rectangular before the start date.
//
// Color buckets: 0, 1..p25, p25..p50, p50..p75, p75+. Bucket boundaries are
// derived from `payload.max` so a quiet user still sees gradation.
//
// Beyond the grid we render: a summary stats row (total / current streak /
// longest streak / best day) and a detail panel that updates on hover and
// can be pinned by clicking a cell. Keyboard accessible via Escape to clear
// the pin; cells are <button> elements so they're tab-focusable.

const DAY_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTH_LABELS = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// Track the currently-rendered heatmap so a single module-scope keydown
// listener can dispatch Esc to the latest instance. Without this, every
// renderHeatmap call (year-picker change, InstantClick re-init) would attach
// a new document listener bound to a stale closure — slow leak + N handlers
// firing on every keystroke.
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

function bucketFor(count, max) {
  if (count <= 0) return 0;
  if (max <= 1) return 4;
  const ratio = count / max;
  if (ratio <= 0.25) return 1;
  if (ratio <= 0.5) return 2;
  if (ratio <= 0.75) return 3;
  return 4;
}

function parseIso(iso) {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

function formatDate(iso) {
  const date = parseIso(iso);
  const day = DAY_LABELS[date.getUTCDay()];
  return `${day} ${MONTH_LABELS[date.getUTCMonth()]} ${date.getUTCDate()}, ${date.getUTCFullYear()}`;
}

function pluralize(count, singular, plural) {
  return count === 1 ? singular : plural;
}

// Walk the day list to compute the longest run anywhere and the current
// run from the most recent day.
function computeStreaks(days) {
  let current = 0;
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

function renderDetail(panelEl, day, labels, pinned) {
  if (!panelEl) return;
  panelEl.innerHTML = '';

  if (!day) {
    const hint = document.createElement('p');
    hint.className = 'heatmap-detail__hint';
    hint.textContent = labels.detailHintLabel;
    panelEl.appendChild(hint);
    panelEl.dataset.pinned = 'false';
    return;
  }

  panelEl.dataset.pinned = pinned ? 'true' : 'false';

  const header = document.createElement('div');
  header.className = 'heatmap-detail__header';
  const title = document.createElement('h3');
  title.className = 'heatmap-detail__title';
  title.textContent = formatDate(day.date);
  header.appendChild(title);

  if (pinned) {
    const pin = document.createElement('span');
    pin.className = 'heatmap-detail__pin';
    pin.textContent = labels.pinnedLabel;
    header.appendChild(pin);
  }
  panelEl.appendChild(header);

  const total = document.createElement('p');
  total.className = 'heatmap-detail__total';
  total.textContent = `${day.total} ${pluralize(day.total, labels.contributionLabel, labels.contributionsLabel)}`;
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

export function renderHeatmap(rootEl, payload, options = {}) {
  if (!rootEl) return;
  rootEl.innerHTML = '';

  const labels = {
    emptyLabel: options.emptyLabel || 'No activity yet.',
    lessLabel: options.lessLabel || 'Less',
    moreLabel: options.moreLabel || 'More',
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
    detailHintLabel: options.detailHintLabel || 'Hover or click any day to see the breakdown.',
    pinnedLabel: options.pinnedLabel || 'Pinned · press Esc to clear',
    noActivityLabel: options.noActivityLabel || 'No activity yet',
  };

  // Stats and detail panel can live in sibling slots provided by the view.
  // Fall back to the immediate parent so the renderer still works in tests
  // that mount a single wrapper.
  const wrapper = options.wrapperEl || rootEl.parentElement || rootEl;
  const statsEl = wrapper.querySelector('[data-heatmap-stats]');
  const panelEl = wrapper.querySelector('[data-heatmap-detail]');

  const days = (payload && payload.days) || [];
  renderStats(statsEl, days, payload && payload.totals, labels);

  if (days.length === 0) {
    const empty = document.createElement('p');
    empty.className = 'heatmap__empty';
    empty.textContent = labels.emptyLabel;
    rootEl.appendChild(empty);
    renderDetail(panelEl, null, labels, false);
    return;
  }

  const max = (payload && payload.max) || 0;
  const dayByDate = new Map();
  days.forEach((d) => dayByDate.set(d.date, d));

  // Anchor the grid to the Sunday on/before the first day.
  const firstDate = parseIso(days[0].date);
  const leadingBlanks = firstDate.getUTCDay();

  const grid = document.createElement('div');
  grid.className = 'heatmap__grid';

  const labelsCol = document.createElement('div');
  labelsCol.className = 'heatmap__day-labels';
  DAY_LABELS.forEach((label) => {
    const span = document.createElement('span');
    span.textContent = label;
    span.className = 'heatmap__day-label';
    labelsCol.appendChild(span);
  });
  grid.appendChild(labelsCol);

  const cells = document.createElement('div');
  cells.className = 'heatmap__cells';

  for (let i = 0; i < leadingBlanks; i += 1) {
    const blank = document.createElement('div');
    blank.className = 'heatmap__cell heatmap__cell--blank';
    blank.setAttribute('aria-hidden', 'true');
    cells.appendChild(blank);
  }

  const cellEls = [];
  days.forEach((day) => {
    const cell = document.createElement('button');
    cell.type = 'button';
    cell.className = 'heatmap__cell';
    cell.dataset.level = String(bucketFor(day.total, max));
    cell.dataset.date = day.date;
    cell.dataset.count = String(day.total);
    cell.setAttribute(
      'title',
      `${day.total} ${pluralize(day.total, labels.contributionLabel, labels.contributionsLabel)} · ${formatDate(day.date)}`,
    );
    cell.setAttribute(
      'aria-label',
      `${formatDate(day.date)}: ${day.total} ${pluralize(day.total, labels.contributionLabel, labels.contributionsLabel)}`,
    );
    cells.appendChild(cell);
    cellEls.push(cell);
  });

  grid.appendChild(cells);

  const legend = document.createElement('div');
  legend.className = 'heatmap__legend';
  const less = document.createElement('span');
  less.textContent = labels.lessLabel;
  legend.appendChild(less);
  for (let i = 0; i <= 4; i += 1) {
    const swatch = document.createElement('span');
    swatch.className = 'heatmap__cell heatmap__cell--legend';
    swatch.dataset.level = String(i);
    legend.appendChild(swatch);
  }
  const more = document.createElement('span');
  more.textContent = labels.moreLabel;
  legend.appendChild(more);

  rootEl.appendChild(grid);
  rootEl.appendChild(legend);

  // Hover updates the detail card; click pins it. A pinned selection
  // survives subsequent hover until cleared via Esc or by clicking the
  // pinned cell again.
  const best = findBestDay(days);
  let pinnedDate = null;

  const showFor = (iso, pinned) => {
    const day = dayByDate.get(iso) || null;
    renderDetail(panelEl, day, labels, !!pinned);
  };

  const showDefault = () => {
    if (best && best.total > 0) renderDetail(panelEl, best, labels, false);
    else renderDetail(panelEl, null, labels, false);
  };

  const refreshPinHighlight = () => {
    cellEls.forEach((c) => {
      c.classList.toggle('heatmap__cell--pinned', c.dataset.date === pinnedDate);
    });
  };

  showDefault();

  cells.addEventListener('mouseover', (event) => {
    const cell = event.target.closest('.heatmap__cell:not(.heatmap__cell--blank)');
    if (!cell || pinnedDate) return;
    showFor(cell.dataset.date, false);
  });

  cells.addEventListener('mouseleave', () => {
    if (pinnedDate) showFor(pinnedDate, true);
    else showDefault();
  });

  cells.addEventListener('focusin', (event) => {
    const cell = event.target.closest('.heatmap__cell:not(.heatmap__cell--blank)');
    if (!cell || pinnedDate) return;
    showFor(cell.dataset.date, false);
  });

  cells.addEventListener('click', (event) => {
    const cell = event.target.closest('.heatmap__cell:not(.heatmap__cell--blank)');
    if (!cell) return;
    pinnedDate = pinnedDate === cell.dataset.date ? null : cell.dataset.date;
    refreshPinHighlight();
    if (pinnedDate) showFor(pinnedDate, true);
    else showDefault();
  });

  // Register this render as the active instance for the module-scope Esc
  // handler. Replacing instead of adding means re-renders don't pile up
  // listeners on document.
  activeInstance = {
    get pinnedDate() { return pinnedDate; },
    clearPin() {
      pinnedDate = null;
      refreshPinHighlight();
      showDefault();
    },
  };
  ensureKeydownListener();
}
