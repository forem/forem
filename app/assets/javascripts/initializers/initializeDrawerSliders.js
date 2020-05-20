/* global swipeState InstantClick initializeSwipeGestures slideSidebar */

function listenForNarrowMenuClick(event) {
  let navLinks = document.getElementsByClassName('narrow-nav-menu');
  let narrowFeedButt = document.getElementById('narrow-feed-butt');

  for (let i = 0; i < navLinks.length; i++) {
    document.getElementById('narrow-nav-menu').classList.remove('showing');
  }
  if (narrowFeedButt) {
    narrowFeedButt.onclick = (_event) => {
      document.getElementById('narrow-nav-menu').classList.add('showing');
    };
  }
  for (let i = 0; i < navLinks.length; i++) {
    navLinks[i].onclick = (_event) => {
      document.getElementById('narrow-nav-menu').classList.remove('showing');
    };
  }
}

function initializeDrawerSliders() {
  if (!initializeSwipeGestures.called) {
    swipeState = 'middle'; // eslint-disable-line no-global-assign
    initializeSwipeGestures();
  }
  if (document.getElementById('on-page-nav-controls')) {
    if (document.getElementById('sidebar-bg-left')) {
      document.getElementById('sidebar-bg-left').onclick = (_event) => {
        swipeState = 'middle'; // eslint-disable-line no-global-assign
        slideSidebar('left', 'outOfView');
      };
    }
    if (document.getElementById('sidebar-bg-right')) {
      document.getElementById('sidebar-bg-right').onclick = (_event) => {
        swipeState = 'middle'; // eslint-disable-line no-global-assign
        slideSidebar('right', 'outOfView');
      };
    }

    if (document.getElementById('on-page-nav-butt-left')) {
      document.getElementById('on-page-nav-butt-left').onclick = (_event) => {
        swipeState = 'left'; // eslint-disable-line no-global-assign
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

    listenForNarrowMenuClick();
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
