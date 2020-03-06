

function initializeHeroBannerClose() {
  let banner = document.getElementById('js-hero-banner');
  let closeIcon = document.getElementById('js-hero-banner__x');

  if (banner && closeIcon) {
    closeIcon.addEventListener('click', () => {
      document.cookie = 'heroBanner=false';
      banner.style.display = 'none';
    });
  }
}
