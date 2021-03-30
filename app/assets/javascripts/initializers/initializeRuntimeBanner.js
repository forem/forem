/* global Runtime */

function handleDismissRuntimeBanner() {
  const runtimeBanner = document.querySelectorAll('.runtime-banner')[0];
  if (runtimeBanner) {
    runtimeBanner.remove();
  }
}

function handleRuntimeBannerDeepLink() {
  const runtimeBanner = document.querySelectorAll('.runtime-banner')[0];
  if (!runtimeBanner) {
    return;
  }

  switch (Runtime.currentOS()) {
    case 'iOS':
      // var iframe = document.createElement('iframe');
      // iframe.html = '<html></html>'
      // runtimeBanner.appendChild(iframe);
      // // iframe.src = `forem://${window.location.href.replace("https://", "")}`;
      // iframe.src = 'forem://'
      // document.getElementById("runtime-banner-iframe").src = "forem://";
      window.location.href = 'forem://';
      break;
    case 'Android':
      // code block
      break;
  }
}

function initializeRuntimeBanner() {
  const bannerIcon = document.querySelectorAll('.runtime-banner__icon')[0];
  const bannerText = document.querySelectorAll('.runtime-banner__text')[0];
  const bannerDismiss = document.querySelectorAll(
    '.runtime-banner__dismiss',
  )[0];

  if (!bannerIcon || !bannerText || !bannerDismiss) {
    return;
  }

  bannerIcon.addEventListener('click', handleRuntimeBannerDeepLink);
  bannerText.addEventListener('click', handleRuntimeBannerDeepLink);
  bannerDismiss.addEventListener('click', handleDismissRuntimeBanner);
}
