import { initCharts, destroyCharts } from '../analytics/dashboard';

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
  // Guard: only run on analytics pages (script re-executes on every InstantClick navigation)
  if (!document.getElementById('week-button')) return;

  const organizationsMenu = document.getElementsByClassName('organization')[0];

  if (!organizationsMenu) {
    initCharts({ organizationId: null });
  } else {
    renderOrgData();
  }
}

// Register InstantClick cleanup ONCE — prevents stale ApexCharts global registry entries
// after DOM swap. The on('change') handler runs while old DOM is still intact, ensuring
// .destroy() properly deregisters charts. Script re-execution handles re-init via initDashboard().
if (window.InstantClick && !window._analyticsChangeRegistered) {
  window._analyticsChangeRegistered = true;
  window.InstantClick.on('change', () => {
    destroyCharts();
  });
}

initDashboard();
