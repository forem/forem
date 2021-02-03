'use strict';

function initializeHeroBannerClose() {
  let bannerWrapper = document.getElementById('hero-html-wrapper');
  let closeIcon = document.getElementById('js-hero-banner__x');

  // Currently js-hero-banner__x button icon ID needs to be written into the abstract html
  // In the future this could be extracted so the implementer doesn't need to worry about it.

  if (bannerWrapper && closeIcon) {
    closeIcon.setAttribute('aria-label', 'Close campaign banner');
    closeIcon.addEventListener('click', () => {
      localStorage.setItem('exited_hero', bannerWrapper.dataset.name);
      bannerWrapper.style.display = 'none';
    });
  }
}
