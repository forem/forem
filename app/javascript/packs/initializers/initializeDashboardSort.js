function buildNavigationUrl(url) {
  const destination = new URL(url, window.location.origin);
  const currentSearchParams = new URLSearchParams(window.location.search);

  currentSearchParams.forEach((value, key) => {
    if (!destination.searchParams.has(key)) {
      destination.searchParams.set(key, value);
    }
  });

  return `${destination.pathname}${destination.search}${destination.hash}`;
}

function selectNavigation(select, urlPrefix) {
  const trigger = document.getElementById(select);
  if (trigger) {
    trigger.addEventListener('change', (event) => {
      let url = event.target.value;
      if (urlPrefix) {
        url = urlPrefix + url;
      }

      url = buildNavigationUrl(url);

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

export { buildNavigationUrl, selectNavigation, initializeDashboardSort };
