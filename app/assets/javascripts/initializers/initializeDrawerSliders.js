import initializeSwipeGestures from './initializeSwipeGestures';

function initializeDrawerSliders() {
  if (!initializeSwipeGestures.called) {
    swipeState = 'middle';
    initializeSwipeGestures();
  }

  if (document.getElementById('on-page-nav-controls')) {
    const drawerSliders = [
      {
        selector: 'sidebar-bg-left',
        swipeState: 'middle',
        side: 'left',
        view: 'outOfView',
      },
      {
        selector: 'sidebar-bg-right',
        swipeState: 'middle',
        side: 'right',
        view: 'outOfView',
      },
      {
        selector: 'on-page-nav-butt-left',
        swipeState: 'left',
        side: 'left',
        view: 'intoView',
      },
      {
        selector: 'on-page-nav-butt-right',
        swipeState: 'right',
        side: 'right',
        view: 'intoView',
      },
    ];

    drawerSliders.forEach(drawerSliders => {
      const element = document.getElementById(drawerSlider.selector);
      if (element) {
        element.onclick = function() {
          swipeState = drawerSliders.swipeState;
          slideSidebar(drawerSliders.side, drawerSliders.view);
        };
      }
    });

    InstantClick.on('change', function() {
      document.getElementsByTagName('body')[0].classList.remove('modal-open');
      slideSidebar('right', 'outOfView');
      slideSidebar('left', 'outOfView');
    });
    listenForNarrowMenuClick();
  }
}

function listenForNarrowMenuClick(event) {
  var navLinks = document.getElementsByClassName('narrow-nav-menu');
  var narrowFeedButt = document.getElementById('narrow-feed-butt');
  for (var x = 0; x < navLinks.length; x++) {
    document.getElementById('narrow-nav-menu').classList.remove('showing');
  }
  if (narrowFeedButt) {
    narrowFeedButt.onclick = function() {
      document.getElementById('narrow-nav-menu').classList.add('showing');
    };
  }
  for (var i = 0; i < navLinks.length; i++) {
    navLinks[i].onclick = function(event) {
      document.getElementById('narrow-nav-menu').classList.remove('showing');
    };
  }
}
