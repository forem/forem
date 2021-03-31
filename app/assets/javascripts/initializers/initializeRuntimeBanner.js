/* global Runtime */

function handleDismissRuntimeBanner() {
  const runtimeBanner = document.querySelectorAll('.runtime-banner')[0];
  if (runtimeBanner) {
    runtimeBanner.remove();
  }
}

function initializeRuntimeBanner() {
  // This will provide the dismiss functionality for the Runtime Banner
  const bannerDismiss = document.querySelectorAll(
    '.runtime-banner__dismiss',
  )[0];
  if (bannerDismiss) {
    bannerDismiss.addEventListener('click', handleDismissRuntimeBanner);
  }

  // If the "Install now"/"Try again" buttons exist in the DOM it means we are
  // trying to deep link into the mobile app after being redirected by the
  // Runtime Banner itself (found in the path `/r/mobile`)
  const installNowButton = document.getElementById('link-to-mobile-install');
  const retryButton = document.getElementById('link-to-mobile-install-retry');
  if (!installNowButton || !retryButton) {
    return;
  }
  // Since we were redirected to `/r/mobile` by the Banner itself we can safely
  // dismiss it by re-using the handleDismissRuntimeBanner function
  handleDismissRuntimeBanner();

  // The target path comes in via GET request query params
  const queryString = window.location.search;
  const urlParams = new URLSearchParams(queryString);
  const targetPath = urlParams.get('deep_link');

  if (Runtime.currentOS() === 'iOS') {
    // The install now must target Apple's AppStore
    installNowButton.href =
      'https://apps.apple.com/us/app/dev-community/id1439094790';

    // We try to deep link directly using the custom scheme and populate the
    // retry button in case the user will need it
    const targetDeepLink = `com.forem.app://${window.location.host}${targetPath}`;
    retryButton.href = targetDeepLink;
    window.location.href = targetDeepLink;
  } else if (Runtime.currentOS() === 'Android') {
    const targetIntent =
      'intent://scan/#Intent;scheme=zxing;package=com.google.zxing.client.android;end';
    retryButton.href = targetIntent;
    installNowButton.href =
      'https://play.google.com/store/apps/details?id=to.dev.dev_android';
  }
}
