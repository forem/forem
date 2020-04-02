'use strict';

function initializeHeroBannerClose() {
  let banner = document.getElementById('js-hero-banner');
  let closeIcon = document.getElementById('js-hero-banner__x');

  if (banner && closeIcon) {
    closeIcon.addEventListener('click', () => {
      localStorage.setItem('exited_hero', 'shecoded'); // Hardcoded. TODO: generalize.
      banner.style.display = 'none';
    });
  }
}
