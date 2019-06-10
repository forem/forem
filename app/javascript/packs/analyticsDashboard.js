import initCharts from '../analytics/dashboard';

window.InstantClick.on('change', () => {
  initCharts();
});

initCharts();
