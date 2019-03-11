import Chart from 'chart.js';

const reactionsCanvas = document.getElementById('reactionsChart');
const commentsCanvas = document.getElementById('commentsChart');

export const reactionsChart = new Chart(reactionsCanvas, {
  type: 'line',
  data: {
    labels: JSON.parse(reactionsCanvas.dataset.labels),
    datasets: [
      {
        label: 'Reaction Total',
        data: JSON.parse(reactionsCanvas.dataset.totalCount),
        // data: [5, 10, 15, 17, 25, 23],
        fill: false,
        borderColor: 'rgb(75, 192, 192)',
        lineTension: 0.1,
      },
      {
        label: 'Total Likes',
        data: JSON.parse(reactionsCanvas.dataset.totalLikes),
        // data: [2, 5, 10, 10, 15, 13],
        fill: false,
        borderColor: 'rgb(229, 100, 100)',
        lineTension: 0.1,
      },
      {
        label: 'Total Unicorns',
        data: JSON.parse(reactionsCanvas.dataset.totalUnicorns),
        // data: [1, 2, 2, 4, 5, 3],
        fill: false,
        borderColor: 'rgb(157, 57, 233)',
        lineTension: 0.1,
      },
      {
        label: 'Total Bookmarks',
        data: JSON.parse(reactionsCanvas.dataset.totalReadinglist),
        // data: [2, 3, 3, 3, 5, 7],
        fill: false,
        borderColor: 'rgb(10, 133, 255)',
        lineTension: 0.1,
      },
    ],
  },
  options: {
    title: {
      display: true,
      text: 'Reactions over the Last Week',
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

export const commentsChart = new Chart(commentsCanvas, {
  type: 'line',
  data: {
    labels: JSON.parse(commentsCanvas.dataset.labels),
    datasets: [
      {
        label: 'Total Comments',
        data: JSON.parse(commentsCanvas.dataset.totalCount),
        fill: false,
        borderColor: 'rgb(75, 192, 192)',
        lineTension: 0.1,
      },
    ],
  },
  options: {
    title: {
      display: true,
      text: 'Comments over the Last Week',
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
