function slideSidebar(side, direction) {
  if (!document.getElementById('sidebar-wrapper-' + side)) {
    return;
  }

  const articlesList = document.getElementById('articles-list');
  const mainContent = document.getElementById('main-content');

  if (direction === 'intoView') {
    if (articlesList) {
      articlesList.classList.add('modal-open');
      articlesList.addEventListener('touchmove', preventDefaultAction, false);
    }

    if (mainContent) {
      mainContent.classList.add('modal-open');
      mainContent.addEventListener('touchmove', preventDefaultAction, false);
    }

    document.body.classList.add('modal-open');
    document
      .getElementById('sidebar-wrapper-' + side)
      .classList.add('swiped-in');
  } else {
    if (articlesList) {
      articlesList.classList.remove('modal-open');
      articlesList.removeEventListener(
        'touchmove',
        preventDefaultAction,
        false,
      );
    }

    if (mainContent) {
      mainContent.classList.remove('modal-open');
      mainContent.removeEventListener('touchmove', preventDefaultAction, false);
    }

    document.body.classList.remove('modal-open');
    document
      .getElementById('sidebar-wrapper-' + side)
      .classList.remove('swiped-in');
  }
}
