'use strict';

function initializeFooterMod() {
  var footerContainer = document.getElementById('footer-container');
  var pageContent = document.getElementById('page-content')
  if (
    footerContainer &&
    pageContent && 
    pageContent.className.indexOf('stories-show') >
      -1 &&
    !document.getElementById('IS_CENTERED_PAGE')
  ) {
    document
      .getElementById('footer-container')
      .classList.remove('centered-footer');
  } else if (footerContainer) {
    document
      .getElementById('footer-container')
      .classList.add('centered-footer');
  }
}
