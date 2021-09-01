import { initCharts } from '../analytics/dashboard';

function renderOrgData() {
  const organizationsArray = Array.from(
    document.getElementsByClassName('organization'),
  );
  const activeOrg = organizationsArray.find(
    (org) => org.getAttribute('aria-current') === 'page',
  );
  const chartData = activeOrg.dataset.organizationId
    ? activeOrg.dataset.organizationId
    : null;

  initCharts({ organizationId: chartData });
}

function initDashboard() {
  const organizationsMenu = document.getElementsByClassName('organization')[0];

  if (!organizationsMenu) {
    initCharts({ organizationId: null });
  } else {
    renderOrgData();
  }
}

initDashboard();
