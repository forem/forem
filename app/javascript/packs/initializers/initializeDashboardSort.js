function selectNavigation(select, urlPrefix) {
  const trigger = document.getElementById(select);
  if (trigger) {
    trigger.addEventListener('change', (event) => {
      let url = event.target.value;
      if (urlPrefix) {
        url = urlPrefix + url;
      }

      InstantClick.preload(url);
      InstantClick.display(url);
    });
  }
}

function initializeDashboardSort() {
  selectNavigation('dashboard_sort', '/dashboard?sort=');
  selectNavigation('dashboard_author');
  selectNavigation('mobile_nav_dashboard');
}

export { selectNavigation, initializeDashboardSort };
