import { callHistoricalAPI, callReferrersAPI } from './client';

function resetActive(activeButton) {
  const buttons = document.getElementsByClassName('timerange-button');
  for (let i = 0; i < buttons.length; i += 1) {
    const button = buttons[i];
    button.classList.remove('selected');
  }

  activeButton.classList.add('selected');
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
  const follows = sumAnalytics(data, 'follows');

  const reactionCard = document.getElementById('reactions-card');
  const commentCard = document.getElementById('comments-card');
  const followerCard = document.getElementById('followers-card');
  const readerCard = document.getElementById('readers-card');

  readerCard.innerHTML = cardHTML(readers, `Readers ${timeRangeLabel}`);
  commentCard.innerHTML = cardHTML(comments, `Comments ${timeRangeLabel}`);
  reactionCard.innerHTML = cardHTML(reactions, `Reactions ${timeRangeLabel}`);
  followerCard.innerHTML = cardHTML(follows, `Followers ${timeRangeLabel}`);
}

function drawChart({ canvas, title, labels, datasets }) {
  const options = {
    legend: {
      position: 'bottom',
    },
    responsive: true,
    title: {
      display: true,
      text: title,
    },
    scales: {
      yAxes: [
        {
          ticks: {
            suggestedMin: 0,
            precision: 0,
          },
        },
      ],
    },
  };

  import('chart.js').then(({ Chart }) => {
    // eslint-disable-next-line no-new
    new Chart(canvas, {
      type: 'line',
      data: {
        labels,
        datasets,
        options,
      },
    });
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
  const followers = parsedData.map((date) => date.follows.total);
  const readers = parsedData.map((date) => date.page_views.total);

  drawChart({
    canvas: document.getElementById('reactions-chart'),
    title: `Reactions ${timeRangeLabel}`,
    labels,
    datasets: [
      {
        label: 'Total',
        data: reactions,
        fill: false,
        borderColor: 'rgb(75, 192, 192)',
        lineTension: 0.1,
      },
      {
        label: 'Likes',
        data: likes,
        fill: false,
        borderColor: 'rgb(229, 100, 100)',
        lineTension: 0.1,
      },
      {
        label: 'Unicorns',
        data: unicorns,
        fill: false,
        borderColor: 'rgb(157, 57, 233)',
        lineTension: 0.1,
      },
      {
        label: 'Bookmarks',
        data: readingList,
        fill: false,
        borderColor: 'rgb(10, 133, 255)',
        lineTension: 0.1,
      },
    ],
  });

  drawChart({
    canvas: document.getElementById('comments-chart'),
    title: `Comments ${timeRangeLabel}`,
    labels,
    datasets: [
      {
        label: 'Comments',
        data: comments,
        fill: false,
        borderColor: 'rgb(75, 192, 192)',
        lineTension: 0.1,
      },
    ],
  });

  drawChart({
    canvas: document.getElementById('followers-chart'),
    title: `New Followers ${timeRangeLabel}`,
    labels,
    datasets: [
      {
        label: 'Followers',
        data: followers,
        fill: false,
        borderColor: 'rgb(10, 133, 255)',
        lineTension: 0.1,
      },
    ],
  });

  drawChart({
    canvas: document.getElementById('readers-chart'),
    title: `Reads ${timeRangeLabel}`,
    labels,
    datasets: [
      {
        label: 'Reads',
        data: readers,
        fill: false,
        borderColor: 'rgb(157, 57, 233)',
        lineTension: 0.1,
      },
    ],
  });
}

function renderReferrers(data) {
  const container = document.getElementById('referrers-container');
  const tableBody = data.domains
    .filter((referrer) => referrer.domain)
    .map((referrer) => {
      return `
      <tr>
        <td>${referrer.domain}</td>
        <td>${referrer.count}</td>
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
        <td>All other external referrers</td>
        <td>${emptyDomainReferrer.count}</td>
      </tr>
    `);
  }

  container.innerHTML = tableBody.join('');
}

function callAnalyticsAPI(date, timeRangeLabel, { organizationId, articleId }) {
  callHistoricalAPI(date, { organizationId, articleId }, (data) => {
    writeCards(data, timeRangeLabel);
    drawCharts(data, timeRangeLabel);
  });

  callReferrersAPI(date, { organizationId, articleId }, (data) => {
    renderReferrers(data);
  });
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
  const beginningOfTime = new Date('2019-4-1');
  callAnalyticsAPI(beginningOfTime, '', { organizationId, articleId });
}

export default function initCharts({ organizationId, articleId }) {
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
