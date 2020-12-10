function closeHeaderMenu() {
  var menuNavButton = document.getElementById('navigation-butt');
  if (menuNavButton) {
    menuNavButton.setAttribute('aria-expanded', 'false');
  }

  var crayonsHeaderMenu = document.getElementById('crayons-header__menu');
  if (crayonsHeaderMenu) {
    setTimeout(() => {
      crayonsHeaderMenu.classList.remove('showing');
    }, 5);
  }
}

function blurHeaderMenu(event, elementId) {
  setTimeout(() => {
    if (document.activeElement !== document.getElementById(elementId)) {
      closeHeaderMenu();
    }
  }, 10);
}

function toggleHeaderMenu() {
  var crayonsHeaderMenu = document.getElementById('crayons-header__menu');
  var menuNavButton = document.getElementById('navigation-butt');

  if (!crayonsHeaderMenu || !menuNavButton) {
    return;
  }

  var crayonsHeaderMenuClassList = crayonsHeaderMenu.classList;
  if (crayonsHeaderMenuClassList.contains('showing')) {
    crayonsHeaderMenuClassList.remove('showing');
    menuNavButton.setAttribute('aria-expanded', 'false');
  } else {
    crayonsHeaderMenuClassList.add('showing');
    menuNavButton.setAttribute('aria-expanded', 'true');

    var firstNavLink = document.getElementById('first-nav-link');
    if (firstNavLink) {
      setTimeout(() => {
        // focus first item on open
        firstNavLink.focus();
      }, 100);
    }
  }
}

function initializeTouchDevice() {
  var isTouchDevice = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|DEV-Native-ios/i.test(
    navigator.userAgent,
  );

  if (navigator.userAgent === 'DEV-Native-ios') {
    document.body.classList.add('dev-ios-native-body');
  }

  var crayonsHeaderMenu = document.getElementById('crayons-header__menu');
  if (crayonsHeaderMenu) {
    var menuNavButton = document.getElementById('navigation-butt');
    var crayonsHeaderMenuClassList = crayonsHeaderMenu.classList;

    setTimeout(() => {
      closeHeaderMenu();
      if (isTouchDevice) {
        // Use a named function instead of anonymous so duplicate event handlers are discarded
        menuNavButton.addEventListener('click', toggleHeaderMenu);
      } else {
        crayonsHeaderMenuClassList.add('desktop');
        menuNavButton.addEventListener('click', (e) => {
          toggleHeaderMenu();
        });
        crayonsHeaderMenu.addEventListener('keyup', (e) => {
          if (
            e.key === 'Escape' &&
            crayonsHeaderMenuClassList.contains('showing')
          ) {
            crayonsHeaderMenuClassList.remove('showing');
            menuNavButton.focus();
          }
        });
        document
          .getElementById('last-nav-link')
          .addEventListener('blur', (e) =>
            blurHeaderMenu(e, 'second-last-nav-link'),
          );
        document.addEventListener('click', (e) => {
          // if clicking outside of the menu, close it
          if (!crayonsHeaderMenu.contains(document.activeElement)) {
            blurHeaderMenu(e, 'first-nav-link');
          }
        });
      }
    }, 10);
  }
}
