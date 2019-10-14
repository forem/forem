'use strict';

function listenForNarrowMenuClick() {
  var navLinks = document.getElementsByClassName('narrow-nav-menu');
  var narrowFeedButt = document.getElementById('narrow-feed-butt');
  var narrowNavMenu = document.getElementById('narrow-nav-menu');
  for (let i = 0; i < navLinks.length; i += 1) {
    narrowNavMenu.classList.remove('showing');
  }
  if (narrowFeedButt) {
    narrowFeedButt.addEventListener('click', () => {
      narrowNavMenu.classList.add('showing');
    });
  }
  for (let i = 0; i < navLinks.length; i += 1) {
    navLinks[i].addEventListener('click', () => {
      narrowNavMenu.classList.remove('showing');
    });
  }
}

/* global initializeSwipeGestures */
/* global slideSidebar */
/* global InstantClick */
function initializeDrawerSliders() {
  if (!initializeSwipeGestures.called) {
    initializeSwipeGestures();
  }
  if (document.getElementById('on-page-nav-controls')) {
    if (document.getElementById('sidebar-bg-left')) {
      document
        .getElementById('sidebar-bg-left')
        .addEventListener('click', () => {
          slideSidebar('left', 'outOfView');
        });
    }
    if (document.getElementById('sidebar-bg-right')) {
      document
        .getElementById('sidebar-bg-right')
        .addEventListener('click', () => {
          slideSidebar('right', 'outOfView');
        });
    }

    if (document.getElementById('on-page-nav-butt-left')) {
      document
        .getElementById('on-page-nav-butt-left')
        .addEventListener('click', () => {
          slideSidebar('left', 'intoView');
        });
    }
    if (document.getElementById('on-page-nav-butt-right')) {
      document
        .getElementById('on-page-nav-butt-right')
        .addEventListener('click', () => {
          slideSidebar('right', 'intoView');
        });
    }
    InstantClick.on('change', () => {
      document.getElementsByTagName('body')[0].classList.remove('modal-open');
      slideSidebar('right', 'outOfView');
      slideSidebar('left', 'outOfView');
    });
    listenForNarrowMenuClick();
  }
}