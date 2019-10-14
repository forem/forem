'use strict';

function initializeDashboardSort() {
  if (document.getElementById('dashhboard_sort')) {
    document
      .getElementById('dashhboard_sort')
      .addEventListener('change', event => {
        window.location = '/dashboard?sort=' + event.target.value;
      });
  }
}
