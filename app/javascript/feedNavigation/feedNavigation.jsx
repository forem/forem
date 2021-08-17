export function initializeMobileNavigationDrawer() {
  const mobileFeedNavButton = document.getElementById('mobile-feed-nav-button');

  if (mobileFeedNavButton.dataset.initialized === 'true') {
    return;
  }

  document
    .getElementById('mobile-feed-nav-button')
    .addEventListener('click', () => {
      Promise.all([import('@crayons/MobileDrawer'), import('preact')]).then(
        ([{ MobileDrawer }, { h, render }]) => {
          // The drawer shows the same navigation links as we use in desktop mode
          const navigationLinks = document.getElementById(
            'feed-navigation-links',
          );
          const container = document.getElementById(
            'mobile-feed-nav-container',
          );

          render(
            <MobileDrawer
              title="Feed options"
              onClose={() => document.getElementById('mobile-drawer')?.remove()}
            >
              <div
                // eslint-disable-next-line react/no-danger
                dangerouslySetInnerHTML={{
                  __html: navigationLinks.outerHTML,
                }}
              />
            </MobileDrawer>,
            container,
          );
        },
      );
    });

  mobileFeedNavButton.dataset.initialized = true;
}

export function initializeFeedOptionsDropdown() {
  import('@utilities/dropdownUtils').then(({ initializeDropdown }) => {
    const feedNavButton = document.getElementById('feed-nav-button');

    if (!feedNavButton.dataset.initialized) {
      const { closeDropdown } = initializeDropdown({
        triggerElementId: 'feed-nav-button',
        dropdownContentId: 'feed-nav-content',
      });

      const innerLinks = document
        .getElementById('feed-nav-content')
        .querySelectorAll('[href]');

      innerLinks.forEach((element) =>
        element.addEventListener('click', closeDropdown),
      );
      feedNavButton.dataset.initialized = true;
    }
  });
}
