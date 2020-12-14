function initializeSpecialNavigationFunctionality() {
  var connectLink = document.getElementById('connect-link');
  var notificationsLink = document.getElementById('notifications-link');
  var moderationLink = document.getElementById('moderation-link');

  if (connectLink) {
    if (document.getElementById('notifications-container')) {
      notificationsLink.blur();
      notificationsLink.classList.add('crayons-header__link--current');
    } else {
      notificationsLink.classList.remove('crayons-header__link--current');
    }
    if (document.getElementById('chat')) {
      connectLink.blur();
      connectLink.classList.add('crayons-header__link--current');
    } else {
      connectLink.classList.remove('crayons-header__link--current');
    }
    if (document.getElementById('moderation-page')) {
      moderationLink.blur();
      moderationLink.classList.add('crayons-header__link--current');
    } else {
      moderationLink.classList.remove('crayons-header__link--current');
    }
  }
}
