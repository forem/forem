import {
  initializeMobileMenu,
  setCurrentPageIconLink,
} from '../topNavigation/utilities';

function getPageEntries() {
  return Object.entries({
    'notifications-index': document.getElementById('notifications-link'),
    'chat_channels-index': document.getElementById('connect-link'),
    'moderations-index': document.getElementById('moderation-link'),
    'stories-search': document.getElementById('search-link'),
  });
}

const menus = [...document.getElementsByClassName('js-hamburger-trigger')];
const moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];

async function getInstantClick() {
  return new Promise((resolve) => {
    const timer = setInterval(() => {
      if (InstantClick) {
        clearInterval(timer);
        resolve(InstantClick);
      }
    });
  });
}

getInstantClick().then((spa) => {
  spa.on('change', function () {
    const { currentPage } = document.getElementById('page-content').dataset;
    setCurrentPageIconLink(currentPage, getPageEntries());
  });
});

const { currentPage } = document.getElementById('page-content').dataset;
setCurrentPageIconLink(currentPage, getPageEntries());
initializeMobileMenu(menus, moreMenus);
