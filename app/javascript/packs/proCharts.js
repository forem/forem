import Chart from 'chart.js';

const reactionsCanvas = document.getElementById('reactionsChart');
const commentsCanvas = document.getElementById('commentsChart');

const weekButton = document.getElementById('week-button');
const monthButton = document.getElementById('month-button');
const infinityButton = document.getElementById('infinity-button');

function resetActive(activeButton) {
  [weekButton, monthButton, infinityButton].forEach(button => {
    button.classList.remove('selected');
  });

  activeButton.classList.add('selected');
}

function callAnalyticsApi(date) {
  fetch(`/api/analytics/historical?start=${date.toISOString().split('T')[0]}`)
    .then(data => data.json())
    .then(data => {
      drawCharts(data);
    });
}

function drawWeekCharts() {
  resetActive(weekButton);
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  callAnalyticsApi(oneWeekAgo);
}

function drawMonthCharts() {
  resetActive(monthButton);
  const oneMonthAgo = new Date();
  oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
  callAnalyticsApi(oneMonthAgo);
}

function drawInfinityCharts() {
  resetActive(infinityButton);
  const beginningOfTime = new Date('2019-4-1');
  callAnalyticsApi(beginningOfTime);
}

drawWeekCharts();
weekButton.addEventListener('click', drawWeekCharts);
monthButton.addEventListener('click', drawMonthCharts);
infinityButton.addEventListener('click', drawInfinityCharts);

function drawCharts(data) {
  const labels = Object.keys(data);
  const parsedData = Object.entries(data).map(date => date[1]);
  const comments = parsedData.map(date => date.comments.total);
  const reactions = parsedData.map(date => date.reactions.total);
  const likes = parsedData.map(date => date.reactions.like);
  const readingList = parsedData.map(date => date.reactions.readinglist);
  const unicorns = parsedData.map(date => date.reactions.unicorn);

  const reactionsChart = new Chart(reactionsCanvas, {
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
        text: 'Reactions this Week',
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

  const commentsChart = new Chart(commentsCanvas, {
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
        text: 'Comments this week',
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
