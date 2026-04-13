import { callHistoricalAPI, callReferrersAPI, callTotalsAPI } from './client';
import { locale } from '@utilities/locale';

const activeCharts = {};

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
    followersCard.innerHTML = cardHTML(sumAnalytics(data, 'follows'), `${locale('core.dashboard_analytics_followers')} ${timeRangeLabel}`);
  }
}

function drawChart({ id, chartType = 'line', showPoints = true, labels, series, colors, strokeDashArray, fillOptions, dataLabels, yaxis, isInfinity = false }) {
  const brushId = `brush-${id}`;
  const mainChartId = `main-${id}`;

  // Convert labels to timestamps for infinity mode (enables datetime x-axis + brush)
  const timestamps = isInfinity ? labels.map((l) => new Date(l).getTime()) : null;

  // X-axis: datetime for infinity (brush support), categories for week/month
  const xaxisConfig = isInfinity
    ? {
        type: 'datetime',
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
    tooltip: {
      shared: true,
      intersect: false,
    },
    grid: {
      borderColor: '#e7e7e7',
    },
  };

  if (fillOptions) {
    options.fill = fillOptions;
  }

  if (dataLabels) {
    options.dataLabels = dataLabels;
  }

  import('apexcharts').then(({ default: ApexCharts }) => {
    // Destroy existing charts (main + brush)
    if (activeCharts[id]) {
      activeCharts[id].destroy();
    }
    if (activeCharts[brushId]) {
      activeCharts[brushId].destroy();
      delete activeCharts[brushId];
    }
    const existingBrushEl = document.getElementById(brushId);
    if (existingBrushEl) existingBrushEl.remove();

    const el = document.getElementById(id);
    if (!el) return;
    el.innerHTML = '';
    const chart = new ApexCharts(el, options);
    chart.render();
    activeCharts[id] = chart;

    // Render brush navigator for infinity mode
    if (isInfinity && timestamps.length > 0) {
      const brushEl = document.createElement('div');
      brushEl.id = brushId;
      el.parentNode.insertBefore(brushEl, el.nextSibling);

      const ninetyDaysMs = 90 * 24 * 60 * 60 * 1000;
      const selMin = Math.max(timestamps[0], timestamps[timestamps.length - 1] - ninetyDaysMs);
      const selMax = timestamps[timestamps.length - 1];

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
        grid: {
          borderColor: '#e7e7e7',
          padding: { left: 10, right: 10 },
        },
      };

      const brushChart = new ApexCharts(brushEl, brushOptions);
      brushChart.render();
      activeCharts[brushId] = brushChart;
    }
  });
}

function drawCharts(data, timeRangeLabel) {
  const labels = Object.keys(data);
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

function removeCardElements() {
  const el = document.getElementsByClassName('summary-stats')[0];
  el && el.remove();
}

function showErrorsOnCharts() {
  const target = ['reactions-chart', 'comments-chart', 'readers-chart', 'followers-chart'];
  target.forEach((id) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.outerHTML = `<p class="m-5" id="${id}">Failed to fetch chart data. If this error persists for a minute, you can try to disable adblock etc. on this page or site.</p>`;
  });
}

function showErrorsOnReferrers() {
  const chartEl = document.getElementById('referrers-chart');
  if (chartEl) chartEl.innerHTML = '';
  document.getElementById('referrers-container').outerHTML =
    '<p class="m-5" id="referrers-container">Failed to fetch referrer data. If this error persists for a minute, you can try to disable adblock etc. on this page or site.</p>';
}

function callAnalyticsAPI(date, timeRangeLabel, { organizationId, articleId }) {
  Promise.all([
    callHistoricalAPI(date, { organizationId, articleId }),
    callTotalsAPI(date, { organizationId, articleId }),
  ])
    .then(([data, totals]) => {
      writeCards(data, timeRangeLabel, totals);
      drawCharts(data, timeRangeLabel);
    })
    .catch((_err) => {
      removeCardElements();
      showErrorsOnCharts();
    });

  callReferrersAPI(date, { organizationId, articleId })
    .then((data) => {
      renderReferrers(data);
    })
    .catch((_err) => showErrorsOnReferrers());
}

function drawWeekCharts({ organizationId, articleId }) {
  resetActive(document.getElementById('week-button'));
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  callAnalyticsAPI(oneWeekAgo, 'this Week', { organizationId, articleId });
}

function drawMonthCharts({ organizationId, articleId }) {
  resetActive(document.getElementById('month-button'));
  const oneMonthAgo = new Date();
  oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
  callAnalyticsAPI(oneMonthAgo, 'this Month', { organizationId, articleId });
}

function drawInfinityCharts({ organizationId, articleId }) {
  resetActive(document.getElementById('infinity-button'));
  // April 1st is when the DEV analytics feature went into place
  const beginningOfTime = new Date('2019-04-01');
  callAnalyticsAPI(beginningOfTime, '', { organizationId, articleId });
}

export function initCharts({ organizationId, articleId }) {
  const weekButton = document.getElementById('week-button');
  weekButton.addEventListener(
    'click',
    drawWeekCharts.bind(null, { organizationId, articleId }),
  );

  const monthButton = document.getElementById('month-button');
  monthButton.addEventListener(
    'click',
    drawMonthCharts.bind(null, { organizationId, articleId }),
  );

  const infinityButton = document.getElementById('infinity-button');
  infinityButton.addEventListener(
    'click',
    drawInfinityCharts.bind(null, { organizationId, articleId }),
  );

  // draw week charts by default
  drawWeekCharts({ organizationId, articleId });
}
