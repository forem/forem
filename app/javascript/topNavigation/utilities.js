function closeHeaderMenu(memberMenu, menuNavButton) {
  if (menuNavButton) {
    menuNavButton.setAttribute('aria-expanded', 'false');
  }

  if (memberMenu) {
    setTimeout(() => {
      memberMenu.classList.remove('showing');
    }, 5);
  }
}

function blurHeaderMenu(memberMenu, menuNavButton, potentiallyActiveElement) {
  setTimeout(() => {
    if (document.activeElement !== potentiallyActiveElement) {
      closeHeaderMenu(memberMenu, menuNavButton);
    }
  }, 10);
}

function toggleHeaderMenu(memberMenu, navigationButton) {
  if (!memberMenu || !navigationButton) {
    return;
  }

  let crayonsHeaderMenuClassList = memberMenu.classList;
  if (crayonsHeaderMenuClassList.contains('showing')) {
    crayonsHeaderMenuClassList.remove('showing');
    navigationButton.setAttribute('aria-expanded', 'false');
  } else {
    crayonsHeaderMenuClassList.add('showing');
    navigationButton.setAttribute('aria-expanded', 'true');

    let firstNavLink = document.getElementById('first-nav-link');
    if (firstNavLink) {
      setTimeout(() => {
        // focus first item on open
        firstNavLink.focus();
      }, 100);
    }
  }
}

export function isTouchDevice() {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|DEV-Native-ios/i.test(
    navigator.userAgent,
  );
}

export function initializeTouchDevice(memberTopMenu, menuNavButton) {
  if (navigator.userAgent === 'DEV-Native-ios') {
    document.body.classList.add('dev-ios-native-body');
  }

  if (memberTopMenu) {
    let crayonsHeaderMenuClassList = memberTopMenu.classList;

    setTimeout(() => {
      closeHeaderMenu(memberTopMenu, menuNavButton);

      if (isTouchDevice()) {
        // Use a named function instead of anonymous so duplicate event handlers are discarded
        menuNavButton.addEventListener('click', (_event) => {
          toggleHeaderMenu(memberTopMenu, menuNavButton);
        });

        document.addEventListener('click', (_event) => {
          // if clicking outside of the menu or on a menu item, close it
          if (document.activeElement.id !== 'member-menu-button') {
            blurHeaderMenu(
              memberTopMenu,
              menuNavButton,
              document.getElementById('first-nav-link'),
            );
          }
        });
      } else {
        crayonsHeaderMenuClassList.add('desktop');
        menuNavButton.addEventListener('click', (_event) => {
          toggleHeaderMenu(memberTopMenu, menuNavButton);
        });
        memberTopMenu.addEventListener('keyup', (e) => {
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
          .addEventListener('blur', (_event) => {
            blurHeaderMenu(
              memberTopMenu,
              menuNavButton,
              document.getElementById('second-last-nav-link'),
            );
          });
        document.addEventListener('click', (_event) => {
          // if clicking outside of the menu, close it
          if (!memberTopMenu.contains(document.activeElement)) {
            blurHeaderMenu(
              memberTopMenu,
              menuNavButton,
              document.getElementById('first-nav-link'),
            );
          }
        });
      }
    }, 10);
  }
}

function toggleBurgerMenu() {
  document.body.classList.toggle('hamburger-open');
}

function showMoreMenu({ target }) {
  target.nextElementSibling.classList.remove('hidden');
  target.classList.add('hidden');
}

/**
 * Gets a reference to InstantClick
 *
 * @param {number} [waitTime=2000] The amount of time to wait
 * until giving up waiting for InstantClick to exist
 *
 * @returns {Promise<object>} The global instance of InstantClick.
 */
export async function getInstantClick(waitTime = 2000) {
  return new Promise((resolve, reject) => {
    const failTimer = setTimeout(() => {
      clearInterval(timer);
      reject(new Error('Unable to resolve InstantClick'));
    }, waitTime);

    const timer = setInterval(() => {
      if (typeof InstantClick !== 'undefined') {
        clearTimeout(failTimer);
        clearInterval(timer);
        resolve(InstantClick);
      }
    });
  });
}

/**
 * Initializes the hamburger menu for mobile navigation
 *
 * @param {HTMLElement[]} menus
 * @param {HTMLElement[]} moreMenus
 */
export function initializeMobileMenu(menus, moreMenus) {
  menus.forEach((trigger) => {
    trigger.addEventListener('click', toggleBurgerMenu);
  });

  moreMenus.forEach((trigger) => {
    trigger.addEventListener('click', showMoreMenu);
  });
}

/**
 * Sets the icon link visually for the current page if the current page
 * is one of the main icon links of the top navigation.
 *
 * @param {string} currentPage
 * @param {[string, HTMLElement][]} pageEntries
 */
export function setCurrentPageIconLink(currentPage, pageEntries) {
  pageEntries
    // Filter out nulls (means the user is logged out so most icons are not in the logged out view)
    .filter(([, iconLink]) => iconLink)
    .forEach(([page, iconLink]) => {
      if (currentPage === page) {
        iconLink.blur();
        iconLink.classList.add('crayons-header__link--current');
      } else {
        iconLink.classList.remove('crayons-header__link--current');
      }
    });
}
