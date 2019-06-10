import Chart from 'chart.js';

function resetActive(activeButton) {
  const buttons = document.getElementsByClassName('timespan-button');
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

function writeCards(data, timeFrame) {
  const readers = sumAnalytics(data, 'page_views');
  const reactions = sumAnalytics(data, 'reactions');
  const comments = sumAnalytics(data, 'comments');
  const follows = sumAnalytics(data, 'follows');

  const reactionCard = document.getElementById('reactions-card');
  const commentCard = document.getElementById('comments-card');
  const followerCard = document.getElementById('followers-card');
  const readerCard = document.getElementById('readers-card');

  readerCard.innerHTML = cardHTML(readers, `Readers ${timeFrame}`);
  commentCard.innerHTML = cardHTML(comments, `Comments ${timeFrame}`);
  reactionCard.innerHTML = cardHTML(reactions, `Reactions ${timeFrame}`);
  followerCard.innerHTML = cardHTML(follows, `Followers ${timeFrame}`);
}

function drawCharts(data, timeRange) {
  const labels = Object.keys(data);
  const parsedData = Object.entries(data).map(date => date[1]);
  const comments = parsedData.map(date => date.comments.total);
  const reactions = parsedData.map(date => date.reactions.total);
  const likes = parsedData.map(date => date.reactions.like);
  const readingList = parsedData.map(date => date.reactions.readinglist);
  const unicorns = parsedData.map(date => date.reactions.unicorn);
  const followers = parsedData.map(date => date.follows.total);
  const readers = parsedData.map(date => date.page_views.total);

  const reactionsCanvas = document.getElementById('reactionsChart');
  const commentsCanvas = document.getElementById('commentsChart');
  const readersCanvas = document.getElementById('readersChart');
  const followersCanvas = document.getElementById('followersChart');

  // eslint-disable-next-line no-new
  new Chart(reactionsCanvas, {
    type: 'line',
    data: {
      labels,
      datasets: [
        {
          label: 'Total',
          data: reactions,
          // data: [5, 10, 15, 17, 25, 23],
          fill: false,
          borderColor: 'rgb(75, 192, 192)',
          lineTension: 0.1,
        },
        {
          label: 'Likes',
          data: likes,
          // data: [2, 5, 10, 10, 15, 13],
          fill: false,
          borderColor: 'rgb(229, 100, 100)',
          lineTension: 0.1,
        },
        {
          label: 'Unicorns',
          data: unicorns,
          // data: [1, 2, 2, 4, 5, 3],
          fill: false,
          borderColor: 'rgb(157, 57, 233)',
          lineTension: 0.1,
        },
        {
          label: 'Bookmarks',
          data: readingList,
          // data: [2, 3, 3, 3, 5, 7],
          fill: false,
          borderColor: 'rgb(10, 133, 255)',
          lineTension: 0.1,
        },
      ],
    },
    options: {
      legend: {
        position: 'bottom',
      },
      responsive: true,
      title: {
        display: true,
        text: `Reactions ${timeRange}`,
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
    },
  });

  // eslint-disable-next-line no-new
  new Chart(commentsCanvas, {
    type: 'line',
    data: {
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
    },
    options: {
      legend: {
        position: 'bottom',
      },
      responsive: true,
      title: {
        display: true,
        text: `Comments ${timeRange}`,
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
    },
  });

  // eslint-disable-next-line no-new
  new Chart(followersCanvas, {
    type: 'line',
    data: {
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
    },
    options: {
      legend: {
        position: 'bottom',
      },
      responsive: true,
      title: {
        display: true,
        text: `New Followers ${timeRange}`,
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
    },
  });

  // eslint-disable-next-line no-new
  new Chart(readersCanvas, {
    type: 'line',
    data: {
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
    },
    options: {
      legend: {
        position: 'bottom',
      },
      responsive: true,
      title: {
        display: true,
        text: `Reads ${timeRange}`,
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
    },
  });
}

function callAnalyticsApi(date, timeRange) {
  fetch(`/api/analytics/historical?start=${date.toISOString().split('T')[0]}`)
    .then(data => data.json())
    .then(data => {
      drawCharts(data, timeRange);
      writeCards(data, timeRange);
    });
}

function drawWeekCharts() {
  resetActive(document.getElementById('week-button'));
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  callAnalyticsApi(oneWeekAgo, 'this Week');
}

function drawMonthCharts() {
  resetActive(document.getElementById('month-button'));
  const oneMonthAgo = new Date();
  oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
  callAnalyticsApi(oneMonthAgo, 'this Month');
}

function drawInfinityCharts() {
  resetActive(document.getElementById('infinity-button'));
  // April 1st is when the DEV analytics feature went into place
  const beginningOfTime = new Date('2019-4-1');
  callAnalyticsApi(beginningOfTime, '');
}

export default function initCharts() {
  const weekButton = document.getElementById('week-button');
  weekButton.addEventListener('click', drawWeekCharts);

  const monthButton = document.getElementById('month-button');
  monthButton.addEventListener('click', drawMonthCharts);

  const infinityButton = document.getElementById('infinity-button');
  infinityButton.addEventListener('click', drawInfinityCharts);

  // draw week charts by default
  drawWeekCharts();
}
