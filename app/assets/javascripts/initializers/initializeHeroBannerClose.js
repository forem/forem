

function setExpiryForCookie() {
  // in the future we  want to set the expiry value from the campaign config based on how long the campaign is running for.
  const date = new Date();
  const daysUntilExpiry = 5;
  date.setDate(date.getDate() + daysUntilExpiry);
  return date.toGMTString();
}

function initializeHeroBannerClose() {
  let banner = document.getElementById('js-hero-banner');
  let closeIcon = document.getElementById('js-hero-banner__x');

  if (banner && closeIcon) {
    closeIcon.addEventListener('click', () => {
      document.cookie = `heroBanner=false; expires=${setExpiryForCookie()};`;
      banner.style.display = 'none';
    });
  }
}
