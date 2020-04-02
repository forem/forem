'use strict';

function initializeHeroBannerClose() {
  let banner = document.getElementById('js-hero-banner');
  let closeIcon = document.getElementById('js-hero-banner__x');

  if (banner && closeIcon) {
    closeIcon.addEventListener('click', () => {
      localStorage.setItem('exited_hero', banner.dataset.name); // Banner data-name needs to include the proper value.
      banner.style.display = 'none';
    });
  }
}
