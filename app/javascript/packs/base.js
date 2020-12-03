import {
  initializeMobileMenu,
  setCurrentPageIconLink,
} from '../topNavigation/utilities';

const menus = [...document.getElementsByClassName('js-hamburger-trigger')];
const moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];

InstantClick.on('change', function () {
  const { currentPage } = document.getElementById('page-content').dataset;
  setCurrentPageIconLink(currentPage);
});

const { currentPage } = document.getElementById('page-content').dataset;
setCurrentPageIconLink(currentPage);
initializeMobileMenu(menus, moreMenus);
