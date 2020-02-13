const drawerSliders = [
  { selector: 'sidebar-bg-left', swipeState: 'middle', side: 'left', view: 'outOfView' },
  { selector: 'sidebar-bg-right', swipeState: 'middle', side: 'right', view: 'outOfView' },
  { selector: 'on-page-nav-butt-left', swipeState: 'left', side: 'left', view: 'intoView' },
  { selector: 'on-page-nav-butt-right', swipeState: 'right', side: 'right', view: 'intoView' },
];

function initializeDrawerSliders() {
  if (!initializeSwipeGestures.called) {
    swipeState = 'middle';
    initializeSwipeGestures();
  }

  if (document.getElementById('on-page-nav-controls')) {
    drawerSliders.forEach(drawerSlider => {
      const element = document.getElementById(drawerSlider.selector);
      if (element) {
        element.onclick = function() {
          swipeState = drawerSlider.swipeState;
          slideSidebar(drawerSlider.side, drawerSlider.view);
        };
      }
    });

    InstantClick.on('change', function() {
      document.body.classList.remove('modal-open');
      slideSidebar('right', 'outOfView');
      slideSidebar('left', 'outOfView');
    });
    listenForNarrowMenuClick();
  }
}

function listenForNarrowMenuClick(event) {
  const navLinks = document.getElementById('narrow-nav-menu');
  const narrowFeedButt = document.getElementById('narrow-feed-butt');
    navLinks.classList.remove('showing');
  if (narrowFeedButt) {
    narrowFeedButt.addEventListener('click', () => {
      navLinks.classList.add('showing');
    });
  }
  navLinks.addEventListener('click', (event) => {
    navLinks.classList.remove('showing');
  });
}
