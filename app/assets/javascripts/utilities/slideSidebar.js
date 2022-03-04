function slideSidebar(side, direction) {
  if (!document.getElementById('sidebar-wrapper-' + side)) {
    return;
  }
  const mainContent =
    document.getElementById('main-content') ||
    document.getElementById('articles-list');
  if (direction === 'intoView') {
    mainContent.classList.add('modal-open');
    document.body.classList.add('modal-open');
    document
      .getElementById('sidebar-wrapper-' + side)
      .classList.add('swiped-in');
    mainContent.addEventListener('touchmove', preventDefaultAction, false);
  } else {
    mainContent.classList.remove('modal-open');
    document.body.classList.remove('modal-open');
    document
      .getElementById('sidebar-wrapper-' + side)
      .classList.remove('swiped-in');
    mainContent.removeEventListener('touchmove', preventDefaultAction, false);
  }
}
