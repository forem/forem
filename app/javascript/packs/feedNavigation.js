import('../feedNavigation/feedNavigation').then(
  ({ initializeFeedOptionsDropdown, initializeMobileNavigationDrawer }) => {
    initializeFeedOptionsDropdown();
    initializeMobileNavigationDrawer();
  },
);
