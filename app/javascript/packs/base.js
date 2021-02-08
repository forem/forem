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

let menus = [...document.getElementsByClassName('js-hamburger-trigger')];
let moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];

getInstantClick().then((spa) => {
  spa.on('change', () => {
    let menus = [...document.getElementsByClassName('js-hamburger-trigger')];
    let moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];
    const { currentPage } = document.getElementById('page-content').dataset;

    setCurrentPageIconLink(currentPage, getPageEntries());
    initializeMobileMenu(menus, moreMenus);
    initializeTouchDevice(memberMenu, menuNavButton);
  });
});

const { currentPage } = document.getElementById('page-content').dataset;
const memberMenu = document.getElementById('crayons-header__menu');
const menuNavButton = document.getElementById('member-menu-button');

setCurrentPageIconLink(currentPage, getPageEntries());
initializeMobileMenu(menus, moreMenus);
initializeTouchDevice(memberMenu, menuNavButton);
