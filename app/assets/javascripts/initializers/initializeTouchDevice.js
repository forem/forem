'use strict';

/* eslint-disable no-undef */

function initializeTouchDevice() {
  var isTouchDevice = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|DEV-Native-ios/i.test(
    navigator.userAgent,
  );
  if (navigator.userAgent === 'DEV-Native-ios') {
    document
      .getElementsByTagName('body')[0]
      .classList.add('dev-ios-native-body');
  }
  setTimeout(() => {
    removeShowingMenu();
    if (isTouchDevice) {
      document.getElementById('navigation-butt').onclick = e => {
        document
          .getElementById('navbar-menu-wrapper')
          .classList.toggle('showing');
      };
    } else {
      document.getElementById('navbar-menu-wrapper').classList.add('desktop');
      document.getElementById('navigation-butt').onfocus = e => {
        document.getElementById('navbar-menu-wrapper').classList.add('showing');
      };
      document.getElementById('last-nav-link').onblur = e => {
        setTimeout(() => {
          console.log(document.activeElement);
          if (
            document.activeElement !==
            document.getElementById('second-last-nav-link')
          ) {
            document
              .getElementById('navbar-menu-wrapper')
              .classList.remove('showing');
          }
        }, 10);
      };
      document.getElementById('navigation-butt').onblur = e => {
        setTimeout(() => {
          if (
            document.activeElement !== document.getElementById('first-nav-link')
          ) {
            document
              .getElementById('navbar-menu-wrapper')
              .classList.remove('showing');
          }
        }, 10);
      };
    }
    document.getElementById('menubg').onclick = e => {
      document
        .getElementById('navbar-menu-wrapper')
        .classList.remove('showing');
    };
  }, 10);
}

function moveShowingMenu() {
  document.getElementById('navbar-menu-wrapper').classList.remove('showing');
  setTimeout(() => {
    document.getElementById('navbar-menu-wrapper').classList.remove('showing');
  }, 5);
  setTimeout(() => {
    document.getElementById('navbar-menu-wrapper').classList.remove('showing');
  }, 150);
}
