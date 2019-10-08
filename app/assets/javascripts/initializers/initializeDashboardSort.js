'use strict';

function initializeDashboardSort() {
  if (document.getElementById('dashhboard_sort')) {
    document.getElementById('dashhboard_sort').onchange = () => {
      window.location = '/dashboard?sort=' + this.value;
    };
  }
}
