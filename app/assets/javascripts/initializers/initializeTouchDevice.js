'use strict';

function getById(className) {
  return document.getElementById(className);
}
function getClassList(className) {
  return getById(className).classList;
}

function blur(event, className) {
  setTimeout(() => {
    if (document.activeElement !== getById(className)) {
      getClassList('navbar-menu-wrapper').remove('showing');
    }
  }, 10);
}

function removeShowingMenu() {
  getClassList('navbar-menu-wrapper').remove('showing');
  setTimeout(() => {
    getClassList('navbar-menu-wrapper').remove('showing');
  }, 5);
  setTimeout(() => {
    getClassList('navbar-menu-wrapper').remove('showing');
  }, 150);
}

function toggleMenu() {
  getClassList('navbar-menu-wrapper').toggle('showing');
}

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
      // Use a named function instead of anonymous so duplicate event handlers are discarded
      getById('navigation-butt').addEventListener('click', toggleMenu);
    } else {
      getClassList('navbar-menu-wrapper').add('desktop');
      getById('navigation-butt').addEventListener('focus', e =>
        getClassList('navbar-menu-wrapper').add('showing'),
      );
      getById('last-nav-link').addEventListener('blur', e =>
        blur(e, 'second-last-nav-link'),
      );
      getById('navigation-butt').addEventListener('blur', e =>
        blur(e, 'first-nav-link'),
      );
    }
    getById('menubg').addEventListener('click', e =>
      getClassList('navbar-menu-wrapper').remove('showing'),
    );
  }, 10);
}
