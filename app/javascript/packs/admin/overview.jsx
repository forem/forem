import Chart from 'chart.js/auto';
import { initializeDropdown } from '@utilities/dropdownUtils';

initializeDropdown({
  triggerElementId: 'timeperiods-trigger',
  dropdownContentId: 'timeperiods-dropdown',
});

// Color sets depending on graph trend
const positiveTrend = {
  backgroundColor: '#ECFDF5',
  borderColor: '#10B981',
};
const negativeTrend = {
  backgroundColor: '#FEF2F2',
  borderColor: '#DC2626',
};

const charts = document.getElementsByClassName('js-chart');

for (const chart of charts) {
  const labels = chart.dataset.days.split(',');
  const data = chart.dataset.values.split(',');

  const trend =
    parseInt(data[data.length - 1], 10) >= parseInt(data[0], 10)
      ? positiveTrend
      : negativeTrend;

  new Chart(chart, {
    type: 'line',
    data: {
      labels,
      datasets: [
        {
          data,
          fill: true,
          tension: 0.5,
          borderWidth: 2,
          ...trend,
        },
      ],
    },
    options: {
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
    },
  });
}
