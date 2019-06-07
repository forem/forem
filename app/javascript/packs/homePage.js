function toggleListingsMinimization() {
  const body = document.getElementsByTagName('body')[0];
  if (body.classList.contains('config_minimize_newest_listings')) {
    // Un-minimize
    localStorage.setItem('config_minimize_newest_listings', 'no');
    body.classList.remove('config_minimize_newest_listings');
  } else {
    // Minimize
    localStorage.setItem('config_minimize_newest_listings', 'yes');
    body.classList.add('config_minimize_newest_listings');
  }
}

const sidebarListingsMinimizeButton = document.getElementById(
  'sidebar-listings-widget-minimize-button',
);
if (sidebarListingsMinimizeButton) {
  sidebarListingsMinimizeButton.addEventListener(
    'click',
    toggleListingsMinimization,
  );
}
