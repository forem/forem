import { initCharts, destroyCharts } from '../analytics/dashboard';

// Resolves the organization context for the current analytics page from the
// nav rendered in dashboards/analytics.erb. Each org tab is an
// `<a data-organization-id="...">`; the active tab is marked with
// `aria-current="page"`. The personal ("Your analytics") tab is also marked
// with `aria-current="page"` but has no `data-organization-id`, so we fall
// back to `null` for it.
//
// Exported for unit testing — see app/javascript/__tests__/analyticsDashboard.test.js.
export function getActiveOrganizationId() {
  const activeTab = document.querySelector(
    '.analytics-nav a[aria-current="page"]',
  );
  if (!activeTab) return null;
  return activeTab.dataset.organizationId || null;
}

function initDashboard() {
  // Guard: only run on analytics pages (script re-executes on every InstantClick navigation)
  if (!document.getElementById('week-button')) return;

  initCharts({ organizationId: getActiveOrganizationId() });
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
