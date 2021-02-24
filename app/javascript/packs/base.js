import {
  initializeMobileMenu,
  setCurrentPageIconLink,
  getInstantClick,
  initializeTouchDevice,
} from '../topNavigation/utilities';

function getPageEntries() {
  return Object.entries({
    'notifications-index': document.getElementById('notifications-link'),
    'chat_channels-index': document.getElementById('connect-link'),
    'moderations-index': document.getElementById('moderation-link'),
    'stories-search': document.getElementById('search-link'),
  });
}

const menuTriggers = [
  ...document.querySelectorAll(
    '.js-hamburger-trigger, .hamburger a:not(.js-nav-more-trigger)',
  ),
];
const moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];

getInstantClick().then((spa) => {
  spa.on('change', () => {
    const { currentPage } = document.getElementById('page-content').dataset;

    setCurrentPageIconLink(currentPage, getPageEntries());
  });
});

const { currentPage } = document.getElementById('page-content').dataset;
const memberMenu = document.getElementById('crayons-header__menu');
const menuNavButton = document.getElementById('member-menu-button');

setCurrentPageIconLink(currentPage, getPageEntries());
initializeMobileMenu(menuTriggers, moreMenus);
initializeTouchDevice(memberMenu, menuNavButton);
