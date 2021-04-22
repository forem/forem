/* global Runtime */

function handleDismissRuntimeBanner(event) {
  const runtimeBanner = document.querySelector('.runtime-banner');
  if (runtimeBanner) {
    runtimeBanner.remove();
  }
}

// A separate function is needed for this because it's impossible to test a
// custom scheme launch in Cypress. More about this here:
// https://medium.com/cypress-io-thailand/understand-stub-spy-apis-that-will-make-your-test-better-than-ever-on-cypress-io-797cb9eb205a
function launchCustomSchemeDeepLink(targetURL) {
  window.location.href = targetURL;
}

function initializeRuntimeBanner() {
  // This will provide the dismiss functionality for the Runtime Banner
  const bannerDismiss = document.querySelector('.runtime-banner__dismiss');
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

    // We try to deep link directly by launching a custom scheme and populate
    // the retry button in case the user will need it
    const targetLink = `com.forem.app://${window.location.host}${targetPath}`;
    retryButton.href = targetLink;
    launchCustomSchemeDeepLink(targetLink);
  } else if (Runtime.currentOS() === 'Android') {
    const targetIntent =
      'intent://scan/#Intent;scheme=zxing;package=com.google.zxing.client.android;end';
    retryButton.href = targetIntent;
    installNowButton.href =
      'https://play.google.com/store/apps/details?id=to.dev.dev_android';
  }
}
