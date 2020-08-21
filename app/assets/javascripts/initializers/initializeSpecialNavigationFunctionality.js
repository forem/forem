function initializeSpecialNavigationFunctionality() {
  var connectLink = document.getElementById('connect-link');
  var notificationsLink = document.getElementById('notifications-link');
  var moderationLink = document.getElementById('moderation-link')
  if (document.getElementById('notifications-container')) {
    notificationsLink.blur();
    notificationsLink.classList.add('top-bar__link--current');
  } else {
    notificationsLink.classList.remove('top-bar__link--current');
  }
  if (document.getElementById('chat')) {
    connectLink.blur();
    connectLink.classList.add('top-bar__link--current');
  } else {
    connectLink.classList.remove('top-bar__link--current');
  }
  if (document.getElementById('moderation-page')) {
    moderationLink.blur();
    moderationLink.classList.add('top-bar__link--current');
  } else {
    moderationLink.classList.remove('top-bar__link--current');
  }

  if (document.body.dataset.userStatus === "logged-in") {
    document.getElementById('top-bar-logged-in').classList.remove('hidden');
    document.getElementById('top-bar-logged-out').classList.add('hidden');
  } else {
    document.getElementById('top-bar-logged-in').classList.add('hidden');
    document.getElementById('top-bar-logged-out').classList.remove('hidden');
  }
}
