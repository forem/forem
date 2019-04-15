function initializeDashboardSort() {
  if (document.getElementById('dashhboard_sort')) {
    document.getElementById('dashhboard_sort').onchange = function() {
      window.location = '/dashboard?sort=' + this.value;
    };
  }
}
