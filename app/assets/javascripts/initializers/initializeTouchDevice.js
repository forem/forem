var crayonsHeaderMenu = document.getElementById('crayons-header__menu');
var crayonsHeaderMenuClassList = crayonsHeaderMenu.classList;
var menuNavButton = document.getElementById('navigation-butt');

function blur(event, className) {
  setTimeout(() => {
    if (document.activeElement !== document.getElementById(className)) {
      crayonsHeaderMenuClassList.remove('showing');
    }
  }, 10);
}

function removeShowingMenu() {
  menuNavButton.setAttribute('aria-expanded', 'false');
  crayonsHeaderMenuClassList.remove('showing');
  setTimeout(() => {
    crayonsHeaderMenuClassList.remove('showing');
  }, 5);
  setTimeout(() => {
    crayonsHeaderMenuClassList.remove('showing');
  }, 150);
}

function toggleMenu() {
  if (crayonsHeaderMenuClassList.contains('showing')) {
      crayonsHeaderMenuClassList.remove('showing');
      menuNavButton.setAttribute('aria-expanded', 'false');
    } else {
      crayonsHeaderMenuClassList.add('showing');
      menuNavButton.setAttribute('aria-expanded', 'true');
    }
}

function initializeTouchDevice() {
  var isTouchDevice = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|DEV-Native-ios/i.test(
    navigator.userAgent,
  );
  if (navigator.userAgent === 'DEV-Native-ios') {
    document.body.classList.add('dev-ios-native-body');
  }
  setTimeout(() => {
    removeShowingMenu();
    if (isTouchDevice) {
      // Use a named function instead of anonymous so duplicate event handlers are discarded
      menuNavButton.addEventListener('click', toggleMenu);
    } else {
      crayonsHeaderMenuClassList.add('desktop');
      menuNavButton.addEventListener('click', (e) => {
        toggleMenu();
      });
      crayonsHeaderMenu.addEventListener('keyup', (e) => {
        if (e.key === 'Escape' && crayonsHeaderMenuClassList.contains('showing')) {
          crayonsHeaderMenuClassList.remove('showing');
          menuNavButton.focus();
        }
      })
      document.getElementById('last-nav-link').addEventListener('blur', (e) =>
        blur(e, 'second-last-nav-link'),
      );
    }
  }, 10);
}
