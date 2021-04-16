import { initCharts } from '../analytics/dashboard';

function initDashboard() {
  const activeOrg = document.querySelector('.organization.active');
  if (activeOrg) {
    initCharts({ organizationId: activeOrg.dataset.organizationId });
  } else {
    initCharts({ organizationId: null });
  }
}

window.InstantClick.on('change', () => {
  initDashboard();
});

initDashboard();
