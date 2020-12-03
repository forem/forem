function toggleBurgerMenu() {
  document.body.classList.toggle('hamburger-open');
}

function showMoreMenu({ target }) {
  target.nextElementSibling.classList.remove('hidden');
  target.classList.add('hidden');
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
  pageEntries.forEach(([page, iconLink]) => {
    if (currentPage === page) {
      iconLink.blur();
      iconLink.classList.add('crayons-header__link--current');
    } else {
      iconLink.classList.remove('crayons-header__link--current');
    }
  });
}
