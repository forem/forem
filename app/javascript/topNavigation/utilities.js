// The mapping here will never change for the duration of the current page life cycle.
const pageLinkMapper = Object.freeze({
  'notifications-index': document.getElementById('notifications-link'),
  'chat_channels-index': document.getElementById('connect-link'),
  'moderations-index': document.getElementById('moderation-link'),
  'stories-search': document.getElementById('search-link'),
});

const defaultPageEntries = Object.entries(pageLinkMapper);

/**
 * Sets the icon link visually for the current page if the current page
 * is one of the main icon links of the top navigation.
 */
export function setCurrentPageIconLink(
  currentPage,
  pageEntries = defaultPageEntries,
) {
  pageEntries.forEach(([page, iconLink]) => {
    if (currentPage === page) {
      iconLink.blur();
      iconLink.classList.add('crayons-header__link--current');
    } else {
      iconLink.classList.remove('crayons-header__link--current');
    }
  });
}
