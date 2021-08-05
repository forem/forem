function closeHeaderMenu(memberMenu, menuNavButton) {
  menuNavButton.setAttribute('aria-expanded', 'false');
  memberMenu.classList.remove('desktop', 'showing');
  delete memberMenu.dataset.clicked;
}

const firstItem = document.getElementById('first-nav-link');

function openHeaderMenu(memberMenu, menuNavButton) {
  menuNavButton.setAttribute('aria-expanded', 'true');
  memberMenu.classList.add('showing');

  if (!firstItem) {
    return;
  }

  // Focus on the first item in the menu
  (function focusFirstItem() {
    if (document.activeElement === firstItem) {
      // The first element has focus
      return;
    }

    firstItem.focus();
    // requestAnimationFrame is faster and more reliable than setTimeout
    // https://swizec.com/blog/how-to-wait-for-dom-elements-to-show-up-in-modern-browsers
    window.requestAnimationFrame(focusFirstItem);
  })();
}

/**
 * Determines whether or not a device is a touch device.
 *
 * @returns true if a touch device, otherwise false.
 */
export function isTouchDevice() {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|DEV-Native-ios/i.test(
    navigator.userAgent,
  );
}

/**
 * Initializes the member navigation menu events.
 *
 * @param {HTMLElement} memberTopMenu The member menu in the top navigation.
 * @param {HTMLElement} menuNavButton The button to activate the member navigation menu.
 */
export function initializeMemberMenu(memberTopMenu, menuNavButton) {
  // Typically using CSS for hovering for the menu is the way to go. But... since we use InstantClick for
  // loading pages, the top header navigation never changes in terms of the DOM references.
  // Because of this, we're using mouse events to mouseover/mouseout on the member's avatar
  // to attach styles to get it to show the menu so that this works on desktop and mobile.
  if (navigator.userAgent === 'DEV-Native-ios') {
    document.body.classList.add('dev-ios-native-body');
  }
  const { classList } = memberTopMenu;
  menuNavButton.addEventListener('click', (_event) => {
    if (classList.contains('showing') && memberTopMenu.dataset.clicked) {
      closeHeaderMenu(memberTopMenu, menuNavButton);
      menuNavButton.focus();
    } else {
      openHeaderMenu(memberTopMenu, menuNavButton);
      memberTopMenu.dataset.clicked = 'clicked';
    }
  });

  if (isTouchDevice()) {
    memberTopMenu.addEventListener('focus', (_event) => {
      menuNavButton.setAttribute('aria-expanded', 'true');
    });
  } else {
    memberTopMenu.addEventListener('mouseover', (_event) => {
      classList.add('desktop');
      openHeaderMenu(memberTopMenu, menuNavButton);
    });
    memberTopMenu.addEventListener('mouseout', (_event) => {
      if (!memberTopMenu.dataset.clicked) {
        closeHeaderMenu(memberTopMenu, menuNavButton);
      }
    });

    memberTopMenu.addEventListener('keyup', (e) => {
      if (e.key === 'Escape' && classList.contains('showing')) {
        closeHeaderMenu(memberTopMenu, menuNavButton);
        menuNavButton.focus();
      }
    });
  }

  memberTopMenu
    .querySelector('.crayons-header__menu__dropdown')
    .addEventListener('click', (event) => {
      // There is a click event listener on the body and we do not want
      // this click to be caught by it
      event.stopPropagation();

      // Close the menu if the user clicked or touched on mobile a link in the menu.
      closeHeaderMenu(memberTopMenu, menuNavButton);
      menuNavButton.focus();
    });

  document.addEventListener('click', (event) => {
    if (event.target.closest('#member-menu-button') === menuNavButton) {
      // The menu navigation button manages it's own click event.
      return;
    }

    // Close the menu if the user clicked or touched on mobile a link in the menu.
    closeHeaderMenu(memberTopMenu, menuNavButton);
  });

  const secondToLastNavLink = document.getElementById('second-last-nav-link');

  document
    .getElementById('last-nav-link')
    .addEventListener('blur', (_event) => {
      // When we tab out of the last link in the member menu, close
      // the menu.
      setTimeout(() => {
        if (document.activeElement === secondToLastNavLink) {
          return;
        }

        closeHeaderMenu(memberTopMenu, menuNavButton);
      }, 10);
    });
}

function toggleBurgerMenu() {
  const { leftNavState = 'closed' } = document.body.dataset;
  document.body.dataset.leftNavState =
    leftNavState === 'open' ? 'closed' : 'open';
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
 * @param {HTMLElement[]} menuTriggers
 * @param {HTMLElement[]} moreMenus
 */
export function initializeMobileMenu(menuTriggers, moreMenus) {
  menuTriggers.forEach((trigger) => {
    trigger.onclick = toggleBurgerMenu;
  });

  moreMenus.forEach((trigger) => {
    trigger.onclick = showMoreMenu;
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
