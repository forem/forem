function initializeFooterMod() {
  if (
    document.getElementById('page-content').className.indexOf('stories-show') > -1
  ) {
    document
      .getElementById('footer-container')
      .classList.remove('centered-footer');
  } else {
    document
      .getElementById('footer-container')
      .classList.add('centered-footer');
  }
}
