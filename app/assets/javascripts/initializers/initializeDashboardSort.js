/* global InstantClick */

'use strict';

function initializeDashboardSort() {
  const sortSelector = document.getElementById('dashboard_sort');
  if (sortSelector) {
    sortSelector.addEventListener('change', (event) => {
      const url = event.target.value;

      InstantClick.preload('/dashboard?sort=' + url);
      InstantClick.display('/dashboard?sort=' + url);
    });
  }

  const sourceSelector = document.getElementById('dashboard_author');
  if (sourceSelector) {
    sourceSelector.addEventListener('change', (event) => {
      const url = event.target.value;

      InstantClick.preload(url);
      InstantClick.display(url);
    });
  }

  const mobileNavDashboard = document.getElementById('mobile_nav_dashboard');
  if (mobileNavDashboard) {
    mobileNavDashboard.addEventListener('change', (event) => {
      const url = event.target.value;

      InstantClick.preload(url);
      InstantClick.display(url);
    });
  }
}
