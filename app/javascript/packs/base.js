import {
  initializeMobileMenu,
  setCurrentPageIconLink,
} from '../topNavigation/utilities';

const pageEntries = Object.entries({
  'notifications-index': document.getElementById('notifications-link'),
  'chat_channels-index': document.getElementById('connect-link'),
  'moderations-index': document.getElementById('moderation-link'),
  'stories-search': document.getElementById('search-link'),
});

const menus = [...document.getElementsByClassName('js-hamburger-trigger')];
const moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];

InstantClick.on('change', function () {
  const { currentPage } = document.getElementById('page-content').dataset;
  setCurrentPageIconLink(currentPage, pageEntries);
});

const { currentPage } = document.getElementById('page-content').dataset;
setCurrentPageIconLink(currentPage, pageEntries);
initializeMobileMenu(menus, moreMenus);
