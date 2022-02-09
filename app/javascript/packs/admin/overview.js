import Chart from 'chart.js/auto';

// General graph configuration
const options = {
  responsive: true,
  elements: {
    point: {
      radius: 3,
      hitRadius: 20,
      hoverBorderWidth: 4,
    },
  },
  layout: {
    padding: 0,
  },
  plugins: {
    legend: false,
    tooltip: {
      mode: 'nearest',
      intersect: true,
      position: 'nearest',
    },
  },
  scales: {
    x: {
      ticks: {
        display: false,
      },
      grid: {
        display: false,
        drawBorder: false,
        drawOnChartArea: false,
        drawTicks: false,
      },
    },
    y: {
      ticks: {
        display: false,
      },
      beginAtZero: true,
      grid: {
        display: false,
        drawBorder: false,
        drawOnChartArea: false,
        drawTicks: false,
      },
    },
  },
};

const datasetOptions = {
  fill: true,
  tension: 0.5,
  borderWidth: 2,
};

// Color sets depending on graph trend
const positiveColors = {
  backgroundColor: '#ECFDF5',
  borderColor: '#10B981',
};
const negativeColors = {
  backgroundColor: '#FEF2F2',
  borderColor: '#DC2626',
};

// This is data for "Last 7 days". Obviously it has to be dynamic.
const labels = [
  'Mar 21',
  'Mar 22',
  'Mar 23',
  'Mar 24',
  'Mar 25',
  'Mar 26',
  'Mar 27',
];
const postsData = [2, 5, 4, 7, 6, 8, 9];
const commentsData = [92, 110, 90, 123, 132, 105, 133];
const reactionsData = [900, 931, 830, 1022, 1450, 1001, 1670];
const newMembersData = [7, 6, 6, 8, 5, 2, 3];

const postsChart = document.getElementById('postsChart');
new Chart(postsChart, {
  type: 'line',
  data: {
    labels,
    datasets: [
      {
        data: postsData,
        ...datasetOptions,
        ...positiveColors,
      },
    ],
  },
  options,
});

const commentsChart = document.getElementById('commentsChart');
new Chart(commentsChart, {
  type: 'line',
  data: {
    labels,
    datasets: [
      {
        data: commentsData,
        ...datasetOptions,
        ...positiveColors,
      },
    ],
  },
  options,
});

const reactionsChart = document.getElementById('reactionsChart');
new Chart(reactionsChart, {
  type: 'line',
  data: {
    labels,
    datasets: [
      {
        data: reactionsData,
        ...datasetOptions,
        ...positiveColors,
      },
    ],
  },
  options,
});

const newMembersChart = document.getElementById('newMembersChart');
new Chart(newMembersChart, {
  type: 'line',
  data: {
    labels,
    datasets: [
      {
        data: newMembersData,
        ...datasetOptions,
        ...negativeColors,
      },
    ],
  },
  options,
});
