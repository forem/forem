import { callHistoricalAPI, callReferrersAPI } from './client';
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

function cardHTML(stat, header) {
  return `
    <h4>${header}</h4>
    <div class="featured-stat">${stat}</div>
  `;
}

function writeCards(data, timeRangeLabel) {
  const readers = sumAnalytics(data, 'page_views');
  const reactions = sumAnalytics(data, 'reactions');
  const comments = sumAnalytics(data, 'comments');

  const reactionCard = document.getElementById('reactions-card');
  const commentCard = document.getElementById('comments-card');
  const readerCard = document.getElementById('readers-card');

  readerCard.innerHTML = cardHTML(readers, `${locale('core.dashboard_analytics_readers')} ${timeRangeLabel}`);
  commentCard.innerHTML = cardHTML(comments, `${locale('core.dashboard_analytics_comments')} ${timeRangeLabel}`);
  reactionCard.innerHTML = cardHTML(reactions, `${locale('core.dashboard_analytics_reactions')} ${timeRangeLabel}`);
}

function drawChart({ id, showPoints = true, labels, series, colors }) {
  const options = {
    chart: {
      type: 'line',
      height: 280,
      toolbar: { show: false },
      zoom: { enabled: false },
      animations: {
        enabled: true,
        easing: 'easeinout',
        speed: 400,
      },
    },
    series,
    colors,
    xaxis: {
      categories: labels,
      labels: {
        rotate: -45,
        rotateAlways: false,
        hideOverlappingLabels: true,
        style: { fontSize: '11px' },
      },
      tickAmount: Math.min(labels.length, 14),
    },
    yaxis: {
      min: 0,
      labels: {
        formatter: (val) => Math.round(val),
      },
    },
    stroke: {
      curve: 'smooth',
      width: 2,
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

  import('apexcharts').then(({ default: ApexCharts }) => {
    const currentChart = activeCharts[id];
    if (currentChart) {
      currentChart.destroy();
    }

    const el = document.getElementById(id);
    el.innerHTML = '';
    const chart = new ApexCharts(el, options);
    chart.render();
    activeCharts[id] = chart;
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
  const readers = parsedData.map((date) => date.page_views.total);

  // When timeRange is "Infinity" we hide the points to avoid over-crowding the UI
  const showPoints = timeRangeLabel !== '';

  drawChart({
    id: 'reactions-chart',
    showPoints,
    labels,
    colors: ['#4bc0c0', '#e56464', '#9d39e9', '#0a85ff'],
    series: [
      { name: 'Total', data: reactions },
      { name: 'Likes', data: likes },
      { name: 'Unicorns', data: unicorns },
      { name: 'Bookmarks', data: readingList },
    ],
  });

  drawChart({
    id: 'comments-chart',
    showPoints,
    labels,
    colors: ['#4bc0c0'],
    series: [{ name: 'Comments', data: comments }],
  });

  drawChart({
    id: 'readers-chart',
    showPoints,
    labels,
    colors: ['#9d39e9'],
    series: [{ name: 'Reads', data: readers }],
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
  const target = ['reactions-chart', 'comments-chart', 'readers-chart'];
  target.forEach((id) => {
    const el = document.getElementById(id);
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
  callHistoricalAPI(date, { organizationId, articleId })
    .then((data) => {
      writeCards(data, timeRangeLabel);
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
