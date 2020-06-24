'use strict';

function initializeDashboardSort() {
  const dashboardSorter = document.getElementById('dashboard_sort');

  if (dashboardSorter) {
    dashboardSorter.addEventListener('change', (event) => {
      window.location.assign(`/dashboard?sort=${event.target.value}`);
    });
  }
}
