/* global swipeState: true, InstantClick, initializeSwipeGestures, slideSidebar */

function initializeDrawerSliders() {
  if (!initializeSwipeGestures.called) {
    swipeState = 'middle';
    initializeSwipeGestures();
  }
  if (document.getElementById('on-page-nav-controls')) {
    if (document.getElementById('sidebar-bg-left')) {
      document.getElementById('sidebar-bg-left').onclick = (_event) => {
        swipeState = 'middle';
        slideSidebar('left', 'outOfView');
      };
    }
    if (document.getElementById('sidebar-bg-right')) {
      document.getElementById('sidebar-bg-right').onclick = (_event) => {
        swipeState = 'middle';
        slideSidebar('right', 'outOfView');
      };
    }

    if (document.getElementById('on-page-nav-butt-left')) {
      document.getElementById('on-page-nav-butt-left').onclick = (_event) => {
        swipeState = 'left';
        slideSidebar('left', 'intoView');
      };
    }
    if (document.getElementById('on-page-nav-butt-right')) {
      document.getElementById('on-page-nav-butt-right').onclick = (_event) => {
        swipeState = 'right'; // eslint-disable-line no-global-assign
        slideSidebar('right', 'intoView');
      };
    }
    InstantClick.on('change', (_event) => {
      document.getElementsByTagName('body')[0].classList.remove('modal-open');
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
