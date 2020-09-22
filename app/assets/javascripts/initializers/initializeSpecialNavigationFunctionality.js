function initializeSpecialNavigationFunctionality() {
  var connectLink = document.getElementById('connect-link');
  var notificationsLink = document.getElementById('notifications-link');
  var moderationLink = document.getElementById('moderation-link');
  var searchLink = document.getElementById('search-link');
  var currentPage = document.getElementById('page-content').dataset.currentPage;

  if (connectLink) {
    if (currentPage === 'notifications-index') {
      notificationsLink.blur();
      notificationsLink.classList.add('top-bar__link--current');
    } else {
      notificationsLink.classList.remove('top-bar__link--current');
    }
    if (currentPage === 'chat_channels-index') {
      connectLink.blur();
      connectLink.classList.add('top-bar__link--current');
    } else {
      connectLink.classList.remove('top-bar__link--current');
    }
    if (currentPage === 'moderations-index') {
      moderationLink.blur();
      moderationLink.classList.add('top-bar__link--current');
    } else {
      moderationLink.classList.remove('top-bar__link--current');
    }
    if (currentPage === 'stories-search') {
      searchLink.blur();
      searchLink.classList.add('top-bar__link--current');
    } else {
      searchLink.classList.remove('top-bar__link--current');
    }
  }
}
