/* global InstantClick, slideSidebar */

function initializeDrawerSliders() {
  if (document.getElementById('on-page-nav-controls')) {
    if (document.getElementById('sidebar-bg-left')) {
      document.getElementById('sidebar-bg-left').onclick = (_event) => {
        slideSidebar('left', 'outOfView');
      };
    }
    if (document.getElementById('sidebar-bg-right')) {
      document.getElementById('sidebar-bg-right').onclick = (_event) => {
        slideSidebar('right', 'outOfView');
      };
    }

    if (document.getElementById('on-page-nav-butt-left')) {
      document.getElementById('on-page-nav-butt-left').onclick = (_event) => {
        slideSidebar('left', 'intoView');
      };
    }
    if (document.getElementById('on-page-nav-butt-right')) {
      document.getElementById('on-page-nav-butt-right').onclick = (_event) => {
        slideSidebar('right', 'intoView');
      };
    }
    InstantClick.on('change', (_event) => {
      document.body.classList.remove('modal-open');
      slideSidebar('right', 'outOfView');
      slideSidebar('left', 'outOfView');
    });
  }

  const feedFilterSelect = document.getElementById('feed-filter-select');

  if (feedFilterSelect) {
    feedFilterSelect.addEventListener('change', (event) => {
      const url = event.target.value;

      InstantClick.preload(url);
      InstantClick.display(url);
    });
  }
}
