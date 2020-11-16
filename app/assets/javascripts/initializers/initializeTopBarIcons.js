function triggerIcon(page, triggerID) {
  var currentPage = document.getElementById('page-content').dataset.currentPage;
  var trigger = document.getElementById(triggerID);

  if (trigger) {
    if (currentPage === page) {
      trigger.blur();
      trigger.classList.add('crayons-header__link--current');
    } else {
      trigger.classList.remove('crayons-header__link--current');
    }
  }
}

function initializeTopBarIcons() {
  triggerIcon('notifications-index', 'notifications-link');
  triggerIcon('chat_channels-index', 'connect-link');
  triggerIcon('moderations-index', 'moderation-link');
  triggerIcon('stories-search', 'search-link');
}

const icons = document.getElementsByClassName('crayons-header__link');

Array.from(icons).forEach((icon) => {
  icon.addEventListener('click', initializeTopBarIcons);
});
