import { callDashboardAPI } from './client';
import { locale } from '@utilities/locale';

// Window-level state survives esbuild IIFE re-execution during InstantClick
// navigation. Without this, each script re-execution creates a new closure scope
// with empty charts/counter, and the on('change') handler (bound to the first
// scope) can't reach later scopes' charts — breaking brush/zoom bindings.
if (!window._analyticsState) {
  window._analyticsState = { activeCharts: {}, apiGeneration: 0 };
}
const activeCharts = window._analyticsState.activeCharts;
const _state = window._analyticsState;

function isDarkMode() {
  return document.body.classList.contains('dark-theme');
}

function resetActive(activeButton) {
  const buttons = document.querySelectorAll(
    '.crayons-tabs--analytics .crayons-tabs__item',
  );
  for (let i = 0; i < buttons.length; i += 1) {
    const button = buttons[i];
    button.classList.remove('crayons-tabs__item--current');
    button.removeAttribute('aria-current');
  }

  activeButton.classList.add('crayons-tabs__item--current');
  activeButton.setAttribute('aria-current', 'page');
}

function sumAnalytics(data, key) {
  return Object.entries(data).reduce((sum, day) => sum + day[1][key].total, 0);
}

function sumBookmarks(data) {
  return Object.entries(data).reduce(
    (sum, day) => sum + (day[1].reactions.readinglist || 0),
    0,
  );
}

function cardHTML(stat, header) {
  return `
    <h4>${header}</h4>
    <div class="featured-stat">${stat}</div>
  `;
}

function readerCardHTML(readers, avgReadTime, header) {
  let html = `
    <h4>${header}</h4>
    <div class="featured-stat">${readers}</div>
  `;
  if (avgReadTime > 0) {
    html += `<p class="color-base-60 fs-s">${locale('core.dashboard_analytics_avg_read_time', { seconds: avgReadTime })}</p>`;
  }
  return html;
}

function reactionCardHTML(reactions, uniqueReactors, header) {
  return `
    <h4>${header}</h4>
    <div class="featured-stat">${reactions}</div>
    <p class="color-base-60 fs-s">${locale('core.dashboard_analytics_unique_reactors', { count: uniqueReactors })}</p>
  `;
}

function writeCards(data, timeRangeLabel, totals) {
  const readers = sumAnalytics(data, 'page_views');
  const totalReactions = sumAnalytics(data, 'reactions');
  const bookmarks = sumBookmarks(data);
  const reactions = totalReactions - bookmarks;
  const comments = sumAnalytics(data, 'comments');
  const uniqueReactors = totals ? (totals.reactions.unique_reactors || 0) : 0;
  const avgReadTime = totals ? (totals.page_views.average_read_time_in_seconds || 0) : 0;

  const reactionCard = document.getElementById('reactions-card');
  const commentCard = document.getElementById('comments-card');
  const readerCard = document.getElementById('readers-card');
  const bookmarkCard = document.getElementById('bookmarks-card');
  const followersCard = document.getElementById('followers-card');

  readerCard.innerHTML = readerCardHTML(readers, avgReadTime, `${locale('core.dashboard_analytics_readers')} ${timeRangeLabel}`);
  reactionCard.innerHTML = reactionCardHTML(reactions, uniqueReactors, `${locale('core.dashboard_analytics_reactions')} ${timeRangeLabel}`);
  commentCard.innerHTML = cardHTML(comments, `${locale('core.dashboard_analytics_comments')} ${timeRangeLabel}`);
  bookmarkCard.innerHTML = cardHTML(bookmarks, `${locale('core.dashboard_analytics_bookmarks')} ${timeRangeLabel}`);
  if (followersCard) {
    const engagementEl = followersCard.querySelector('.follower-engagement');
    followersCard.innerHTML = cardHTML(sumAnalytics(data, 'follows'), `${locale('core.dashboard_analytics_followers')} ${timeRangeLabel}`);
    if (engagementEl) followersCard.appendChild(engagementEl);
  }
}

function drawChart({ id, chartType = 'line', showPoints = true, labels, series, colors, strokeDashArray, fillOptions, dataLabels, yaxis, isInfinity = false }) {
  const brushId = `brush-${id}`;
  const mainChartId = `main-${id}`;

  // Convert labels to timestamps for infinity mode (enables datetime x-axis + brush)
  const timestamps = isInfinity ? labels.map((l) => new Date(l).getTime()) : null;

  // Calculate 90-day selection window for infinity mode (used by both main chart and brush)
  let selMin, selMax;
  if (isInfinity && timestamps && timestamps.length > 0) {
    const ninetyDaysMs = 90 * 24 * 60 * 60 * 1000;
    selMin = Math.max(timestamps[0], timestamps[timestamps.length - 1] - ninetyDaysMs);
    selMax = timestamps[timestamps.length - 1];
  }

  // X-axis: datetime for infinity (brush support), categories for week/month
  const xaxisConfig = isInfinity
    ? {
        type: 'datetime',
        min: selMin,
        max: selMax,
        labels: { datetimeUTC: false, style: { fontSize: '11px' } },
      }
    : {
        categories: labels,
        labels: {
          rotate: -45,
          rotateAlways: false,
          hideOverlappingLabels: true,
          style: { fontSize: '11px' },
        },
        tickAmount: Math.min(labels.length, 14),
      };

  // For infinity, pair values with timestamps: [[ts, val], ...]
  const chartSeries = isInfinity
    ? series.map((s) => ({ ...s, data: s.data.map((val, i) => [timestamps[i], val]) }))
    : series;

  const options = {
    chart: {
      ...(isInfinity ? { id: mainChartId } : {}),
      type: chartType,
      height: 320,
      toolbar: { show: isInfinity, autoSelected: 'zoom' },
      zoom: { enabled: isInfinity },
      animations: {
        enabled: true,
        easing: 'easeinout',
        speed: 400,
      },
    },
    series: chartSeries,
    colors,
    xaxis: xaxisConfig,
    yaxis: yaxis || {
      min: 0,
      labels: {
        formatter: (val) => Math.round(val),
      },
    },
    stroke: {
      curve: 'smooth',
      width: 2,
      dashArray: strokeDashArray || Array(series.length).fill(0),
    },
    markers: {
      size: showPoints ? 3 : 0,
    },
    legend: {
      position: 'top',
    },
    theme: {
      mode: isDarkMode() ? 'dark' : 'light',
    },
    tooltip: {
      shared: true,
      intersect: false,
    },
    grid: {
      borderColor: isDarkMode() ? '#333' : '#e7e7e7',
    },
  };

  if (fillOptions) {
    options.fill = fillOptions;
  }

  if (dataLabels) {
    options.dataLabels = dataLabels;
  }

  import('apexcharts').then(({ default: ApexCharts }) => {
    // Destroy existing charts (brush first, then main — order matters for ApexCharts registry)
    if (activeCharts[brushId]) {
      activeCharts[brushId].destroy();
      delete activeCharts[brushId];
    }
    const existingBrushEl = document.getElementById(brushId);
    if (existingBrushEl) existingBrushEl.remove();

    if (activeCharts[id]) {
      activeCharts[id].destroy();
      delete activeCharts[id];
    }

    const el = document.getElementById(id);
    if (!el) return;
    el.innerHTML = '';
    const chart = new ApexCharts(el, options);
    activeCharts[id] = chart;

    // Render main chart, then brush — brush must bind after main is in the registry
    chart.render().then(() => {
      if (!isInfinity || !timestamps || timestamps.length === 0) return;

      const brushEl = document.createElement('div');
      brushEl.id = brushId;
      el.parentNode.insertBefore(brushEl, el.nextSibling);

      const brushOptions = {
        chart: {
          type: 'area',
          height: 100,
          brush: {
            target: mainChartId,
            enabled: true,
          },
          selection: {
            enabled: true,
            xaxis: { min: selMin, max: selMax },
          },
          toolbar: { show: false },
          animations: { enabled: false },
        },
        series: [{ name: chartSeries[0].name, data: chartSeries[0].data }],
        colors: [colors[0]],
        xaxis: {
          type: 'datetime',
          labels: { datetimeUTC: false, style: { fontSize: '10px' } },
          axisBorder: { show: false },
        },
        yaxis: {
          min: 0,
          labels: { show: false },
        },
        fill: {
          type: 'gradient',
          gradient: { opacityFrom: 0.3, opacityTo: 0.05 },
        },
        stroke: { width: 1, curve: 'smooth' },
        legend: { show: false },
        dataLabels: { enabled: false },
        theme: {
          mode: isDarkMode() ? 'dark' : 'light',
        },
        grid: {
          borderColor: isDarkMode() ? '#333' : '#e7e7e7',
          padding: { left: 10, right: 10 },
        },
      };

      const brushChart = new ApexCharts(brushEl, brushOptions);
      brushChart.render();
      activeCharts[brushId] = brushChart;
    });
  });
}

function drawCharts(data, timeRangeLabel) {
  const labels = Object.keys(data);

  if (labels.length === 0) {
    ['reactions-chart', 'comments-chart', 'readers-chart', 'followers-chart'].forEach((id) => {
      const el = document.getElementById(id);
      if (el) {
        el.innerHTML = `<p class="color-base-60 fs-s m-5 text-center">${locale('core.dashboard_analytics_no_data')}</p>`;
      }
    });
    return;
  }

  const parsedData = Object.entries(data).map((date) => date[1]);
  const comments = parsedData.map((date) => date.comments.total);
  const reactions = parsedData.map((date) => date.reactions.total);
  const likes = parsedData.map((date) => date.reactions.like);
  const readingList = parsedData.map((date) => date.reactions.readinglist);
  const unicorns = parsedData.map((date) => date.reactions.unicorn);
  const explodingHeads = parsedData.map((date) => date.reactions.exploding_head);
  const raisedHands = parsedData.map((date) => date.reactions.raised_hands);
  const fires = parsedData.map((date) => date.reactions.fire);
  // Total excluding bookmarks — bookmarks are shown separately
  const reactionsExclBookmarks = reactions.map((val, i) => val - readingList[i]);
  const readers = parsedData.map((date) => date.page_views.total);
  const avgReadTime = parsedData.map((date) => date.page_views.average_read_time_in_seconds || 0);
  const followers = parsedData.map((date) => date.follows.total);
  // Cumulative running total for follower growth
  const cumulativeFollowers = followers.reduce((acc, val) => {
    acc.push((acc.length ? acc[acc.length - 1] : 0) + val);
    return acc;
  }, []);

  // Infinity mode: brush navigator + datetime x-axis
  const isInfinity = timeRangeLabel === '';
  // When timeRange is "Infinity" we hide the points to avoid over-crowding the UI
  const showPoints = !isInfinity;

  drawChart({
    id: 'reactions-chart',
    showPoints,
    labels,
    isInfinity,
    colors: ['#4bc0c0', '#e56464', '#9d39e9', '#f59e0b', '#10b981', '#ef4444', '#0a85ff'],
    // dashArray: 0 = solid for first 6 series, 5 = dashed for Bookmarks (last)
    strokeDashArray: [0, 0, 0, 0, 0, 0, 5],
    series: [
      { name: 'Total', data: reactionsExclBookmarks },
      { name: 'Likes', data: likes },
      { name: 'Unicorns', data: unicorns },
      { name: 'Exploding Heads', data: explodingHeads },
      { name: 'Raised Hands', data: raisedHands },
      { name: 'Fire', data: fires },
      { name: 'Bookmarks', data: readingList },
    ],
  });

  drawChart({
    id: 'comments-chart',
    showPoints,
    labels,
    isInfinity,
    colors: ['#4bc0c0'],
    series: [{ name: 'Comments', data: comments }],
  });

  drawChart({
    id: 'readers-chart',
    showPoints,
    labels,
    isInfinity,
    colors: ['#9d39e9', '#10b981'],
    strokeDashArray: [0, 4],
    series: [
      { name: 'Reads', data: readers },
      { name: 'Avg Read Time (s)', data: avgReadTime },
    ],
    yaxis: [
      {
        min: 0,
        title: { text: 'Reads', style: { color: '#9d39e9', fontSize: '12px' } },
        labels: { formatter: (val) => Math.round(val) },
      },
      {
        opposite: true,
        min: 0,
        title: { text: 'Avg Read Time (s)', style: { color: '#10b981', fontSize: '12px' } },
        labels: { formatter: (val) => `${Math.round(val)}s` },
      },
    ],
  });

  drawChart({
    id: 'followers-chart',
    chartType: 'area',
    showPoints: false,
    labels,
    isInfinity,
    colors: ['#f59e0b'],
    series: [{ name: 'Total Followers', data: cumulativeFollowers }],
    fillOptions: {
      type: 'gradient',
      gradient: {
        shadeIntensity: 1,
        opacityFrom: 0.4,
        opacityTo: 0.05,
        stops: [0, 95, 100],
      },
    },
    dataLabels: {
      enabled: true,
      formatter: (val, { dataPointIndex }) => {
        // Show label only when the cumulative total increased (new followers gained)
        if (dataPointIndex === 0) return val > 0 ? val : '';
        return cumulativeFollowers[dataPointIndex] !== cumulativeFollowers[dataPointIndex - 1] ? val : '';
      },
      offsetY: -8,
      style: {
        fontSize: '11px',
        fontWeight: 600,
        colors: ['#f59e0b'],
      },
      background: {
        enabled: true,
        foreColor: '#fff',
        borderRadius: 3,
        padding: 4,
        borderWidth: 0,
        dropShadow: { enabled: false },
      },
    },
  });
}

function drawReferrerChart(data) {
  const MAX_SLICES = 8;
  const referrers = data.domains
    .map((r) => ({ label: r.domain || 'Other', count: r.count }))
    .sort((a, b) => b.count - a.count);

  if (referrers.length === 0) return;

  let labels, series;
  if (referrers.length <= MAX_SLICES) {
    labels = referrers.map((r) => r.label);
    series = referrers.map((r) => r.count);
  } else {
    const top = referrers.slice(0, MAX_SLICES - 1);
    const rest = referrers.slice(MAX_SLICES - 1);
    const otherCount = rest.reduce((sum, r) => sum + r.count, 0);
    labels = [...top.map((r) => r.label), 'Other'];
    series = [...top.map((r) => r.count), otherCount];
  }

  const options = {
    chart: {
      type: 'donut',
      height: 300,
      animations: {
        enabled: true,
        easing: 'easeinout',
        speed: 400,
      },
    },
    theme: {
      mode: isDarkMode() ? 'dark' : 'light',
    },
    series,
    labels,
    legend: {
      position: 'bottom',
      fontSize: '13px',
    },
    tooltip: {
      y: {
        formatter: (val) => `${val} views`,
      },
    },
    dataLabels: {
      enabled: false,
    },
    plotOptions: {
      pie: {
        donut: {
          size: '55%',
        },
      },
    },
  };

  import('apexcharts').then(({ default: ApexCharts }) => {
    const currentChart = activeCharts['referrers-chart'];
    if (currentChart) {
      currentChart.destroy();
    }

    const el = document.getElementById('referrers-chart');
    el.innerHTML = '';
    const chart = new ApexCharts(el, options);
    chart.render();
    activeCharts['referrers-chart'] = chart;
  });
}

function renderReferrers(data) {
  const container = document.getElementById('referrers-container');

  if (!data.domains || data.domains.length === 0) {
    container.innerHTML = `<tr><td colspan="2" class="color-base-60 fs-s p-4 text-center">${locale('core.dashboard_analytics_no_referrers')}</td></tr>`;
    const chartEl = document.getElementById('referrers-chart');
    if (chartEl) chartEl.innerHTML = '';
    return;
  }

  const tableBody = data.domains
    .filter((referrer) => referrer.domain)
    .map((referrer) => {
      return `
      <tr>
        <td class="align-left">${referrer.domain}</td>
        <td class="align-right">${referrer.count}</td>
      </tr>
    `;
    });

  // add referrers with empty domains if present
  const emptyDomainReferrer = data.domains.filter(
    (referrer) => !referrer.domain,
  )[0];
  if (emptyDomainReferrer) {
    tableBody.push(`
      <tr>
        <td class="align-left">All other external referrers</td>
        <td class="align-right">${emptyDomainReferrer.count}</td>
      </tr>
    `);
  }

  container.innerHTML = tableBody.join('');
  drawReferrerChart(data);
}

function renderTopContributors(data) {
  const container = document.getElementById('top-contributors-container');
  if (!container) return;

  container.innerHTML = '';

  if (!data || data.length === 0) {
    const emptyMsg = document.createElement('p');
    emptyMsg.className = 'color-base-60 fs-s p-4';
    emptyMsg.textContent = locale('core.top_contributors_empty');
    container.appendChild(emptyMsg);
    return;
  }

  const note = document.createElement('p');
  note.className = 'fs-xs color-base-50 mt-0 mb-3';
  note.style.fontStyle = 'italic';
  note.textContent = locale('core.top_contributors_weight_note');
  container.appendChild(note);

  data.forEach((contributor, index) => {
    const row = document.createElement('div');
    row.className = `flex items-center gap-3 py-3${index > 0 ? ' border-t-1 border-base-10' : ''}`;

    const rank = document.createElement('span');
    rank.className = 'color-base-50 fs-s fw-bold';
    rank.style.minWidth = '1.75rem';
    rank.style.textAlign = 'right';
    rank.textContent = index + 1;
    row.appendChild(rank);

    const avatar = document.createElement('img');
    avatar.className = 'crayons-avatar crayons-avatar--l';
    avatar.src = contributor.profile_image;
    avatar.alt = contributor.username;
    avatar.width = 40;
    avatar.height = 40;
    avatar.loading = 'lazy';
    row.appendChild(avatar);

    const info = document.createElement('div');
    info.className = 'flex-1 min-w-0';

    const nameLink = document.createElement('a');
    nameLink.href = `/${contributor.username}`;
    nameLink.className = 'fw-bold fs-base block truncate color-base-90';
    nameLink.textContent = contributor.name || contributor.username;
    info.appendChild(nameLink);

    const counts = document.createElement('div');
    counts.className = 'flex items-center gap-3 mt-1';

    if (contributor.reactions_count > 0) {
      const rSpan = document.createElement('span');
      rSpan.className = 'fs-s color-base-70';
      const rIcon = document.createElement('span');
      rIcon.style.color = '#4bc0c0';
      rIcon.textContent = '\u2764\uFE0F';
      const rStrong = document.createElement('strong');
      rStrong.textContent = contributor.reactions_count;
      rSpan.appendChild(rIcon);
      rSpan.append(' ', rStrong, ' ', locale('core.top_contributors_reactions'));
      counts.appendChild(rSpan);
    }

    if (contributor.comments_count > 0) {
      const cSpan = document.createElement('span');
      cSpan.className = 'fs-s color-base-70';
      const cIcon = document.createElement('span');
      cIcon.style.color = '#9d39e9';
      cIcon.textContent = '\uD83D\uDCAC';
      const cStrong = document.createElement('strong');
      cStrong.textContent = contributor.comments_count;
      cSpan.appendChild(cIcon);
      cSpan.append(' ', cStrong, ' ', locale('core.top_contributors_comments'));
      counts.appendChild(cSpan);
    }

    info.appendChild(counts);
    row.appendChild(info);
    container.appendChild(row);
  });
}

function renderFollowerEngagement(data) {
  const card = document.getElementById('followers-card');
  if (!card) return;

  // Remove any previous engagement line
  const existing = card.querySelector('.follower-engagement');
  if (existing) existing.remove();

  if (!data || data.total_followers === 0) return;

  const p = document.createElement('p');
  p.className = 'follower-engagement color-base-60 fs-s';
  p.appendChild(document.createTextNode(locale('core.follower_engagement_ratio', { ratio: data.ratio })));
  p.appendChild(document.createElement('br'));
  p.appendChild(document.createTextNode(locale('core.follower_engagement_detail', { engaged: data.engaged_followers, total: data.total_followers })));
  card.appendChild(p);
}

function showLoadingPlaceholders() {
  const cardIds = ['readers-card', 'reactions-card', 'comments-card', 'bookmarks-card', 'followers-card'];
  cardIds.forEach((id) => {
    const el = document.getElementById(id);
    if (el && !el.querySelector('.analytics-loading')) {
      el.innerHTML = '<div class="analytics-loading crayons-scaffold-loading w-75 h-0 py-4 mx-auto my-3"></div>';
    }
  });

  const chartIds = ['readers-chart', 'reactions-chart', 'comments-chart', 'followers-chart', 'referrers-chart'];
  chartIds.forEach((id) => {
    const el = document.getElementById(id);
    if (el && !el.querySelector('.analytics-loading')) {
      el.innerHTML = '<div class="analytics-loading crayons-scaffold-loading w-100 mx-auto" style="height:200px"></div>';
    }
  });
}

function removeCardElements() {
  const el = document.getElementsByClassName('summary-stats')[0];
  el && el.remove();
}

function retryButtonHTML() {
  return '<button type="button" class="crayons-btn crayons-btn--secondary mt-2" data-analytics-retry>Retry</button>';
}

function bindRetryButtons(root = document) {
  root.querySelectorAll('[data-analytics-retry]').forEach((btn) => {
    if (btn.dataset.analyticsRetryBound === 'true') return;
    btn.dataset.analyticsRetryBound = 'true';
    btn.addEventListener('click', () => {
      if (typeof _state.lastDraw === 'function') {
        _state.lastDraw(_state.lastContext || {});
      }
    });
  });
}

function showErrorsOnCharts() {
  const target = ['reactions-chart', 'comments-chart', 'readers-chart', 'followers-chart'];
  target.forEach((id) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.outerHTML = `<div class="m-5" id="${id}"><p>Failed to fetch chart data. If this error persists for a minute, you can try to disable adblock etc. on this page or site.</p>${retryButtonHTML()}</div>`;
  });
  bindRetryButtons();
}

function showErrorsOnReferrers() {
  const chartEl = document.getElementById('referrers-chart');
  if (chartEl) chartEl.innerHTML = '';
  const container = document.getElementById('referrers-container');
  if (container) {
    // referrers-container is a <tbody>; preserve it and inject a valid table row
    // so the surrounding <table> markup stays well-formed.
    container.innerHTML = `<tr><td colspan="2" class="p-5"><p>Failed to fetch referrer data. If this error persists for a minute, you can try to disable adblock etc. on this page or site.</p>${retryButtonHTML()}</td></tr>`;
  }
  bindRetryButtons();
}

function callAnalyticsAPI(date, timeRangeLabel, { organizationId, articleId }) {
  const generation = ++_state.apiGeneration;

  // Destroy existing charts before showing placeholders to clean ApexCharts registry
  Object.keys(activeCharts).forEach((key) => {
    activeCharts[key].destroy();
    delete activeCharts[key];
  });
  document.querySelectorAll('[id^="brush-"]').forEach((el) => el.remove());

  showLoadingPlaceholders();

  // Single bundled request: /api/analytics/dashboard returns all five panels
  // (historical, totals, referrers, top_contributors, follower_engagement) in
  // one response. This replaces 5 parallel GETs that systematically tripped
  // the Rack::Attack api_throttle (3 GET/sec per IP) and caused "Failed to
  // fetch chart data" errors in production.
  callDashboardAPI(date, { organizationId, articleId })
    .then((data) => {
      if (generation !== _state.apiGeneration) return;

      writeCards(data.historical, timeRangeLabel, data.totals);
      drawCharts(data.historical, timeRangeLabel);
      renderReferrers(data.referrers);

      if (document.getElementById('top-contributors-container')) {
        renderTopContributors(data.top_contributors);
      }

      if (document.getElementById('followers-card')) {
        renderFollowerEngagement(data.follower_engagement);
      }
    })
    .catch((_err) => {
      if (generation !== _state.apiGeneration) return;
      showErrorsOnCharts();
      showErrorsOnReferrers();
    });
}

function drawWeekCharts({ organizationId, articleId }) {
  _state.lastDraw = drawWeekCharts;
  _state.lastContext = { organizationId, articleId };
  resetActive(document.getElementById('week-button'));
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  callAnalyticsAPI(oneWeekAgo, 'this Week', { organizationId, articleId });
}

function drawMonthCharts({ organizationId, articleId }) {
  _state.lastDraw = drawMonthCharts;
  _state.lastContext = { organizationId, articleId };
  resetActive(document.getElementById('month-button'));
  const oneMonthAgo = new Date();
  oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
  callAnalyticsAPI(oneMonthAgo, 'this Month', { organizationId, articleId });
}

function drawInfinityCharts({ organizationId, articleId }) {
  _state.lastDraw = drawInfinityCharts;
  _state.lastContext = { organizationId, articleId };
  resetActive(document.getElementById('infinity-button'));
  // April 1st is when the DEV analytics feature went into place
  const beginningOfTime = new Date('2019-04-01');
  callAnalyticsAPI(beginningOfTime, '', { organizationId, articleId });
}

export function destroyCharts() {
  // Invalidate any in-flight API responses
  _state.apiGeneration++;
  Object.keys(activeCharts).forEach((key) => {
    activeCharts[key].destroy();
    delete activeCharts[key];
  });
  // Remove dynamically created brush elements
  document.querySelectorAll('[id^="brush-"]').forEach((el) => el.remove());
}

export function initCharts({ organizationId, articleId }) {
  // Destroy any leftover charts from previous navigation
  destroyCharts();

  const weekButton = document.getElementById('week-button');
  const monthButton = document.getElementById('month-button');
  const infinityButton = document.getElementById('infinity-button');

  // Replace elements to remove all old event listeners cleanly
  const newWeek = weekButton.cloneNode(true);
  const newMonth = monthButton.cloneNode(true);
  const newInfinity = infinityButton.cloneNode(true);
  weekButton.replaceWith(newWeek);
  monthButton.replaceWith(newMonth);
  infinityButton.replaceWith(newInfinity);

  newWeek.addEventListener(
    'click',
    drawWeekCharts.bind(null, { organizationId, articleId }),
  );

  newMonth.addEventListener(
    'click',
    drawMonthCharts.bind(null, { organizationId, articleId }),
  );

  newInfinity.addEventListener(
    'click',
    drawInfinityCharts.bind(null, { organizationId, articleId }),
  );

  // draw week charts by default
  drawWeekCharts({ organizationId, articleId });
}
