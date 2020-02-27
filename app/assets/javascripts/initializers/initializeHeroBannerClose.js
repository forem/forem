'use strict';

function initializeHeroBannerClose() {
  let banner = document.getElementById("js-she-coded-hero-banner");
  let closeIcon = document.getElementById("js-she-coded-hero-banner__x");

  if (banner && closeIcon) {
    closeIcon.onclick = (e) => {
      document.cookie = "heroBanner=false";
      banner.style.display = "none";
    }
  }
}
