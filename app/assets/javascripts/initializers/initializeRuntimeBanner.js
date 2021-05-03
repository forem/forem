/* global Runtime */

/**
 * Callback that dismisses the Runtime Banner
 */
function handleDismissRuntimeBanner() {
  const runtimeBanner = document.querySelector('.runtime-banner');
  if (runtimeBanner) {
    runtimeBanner.remove();
  }
}

/**
 * This function redirects the browser to custom schemes, i.e. deep link into
 * mobile apps. A separate function is needed in this case in order to test
 * the feature using Cypress. More details can be found here:
 * https://medium.com/cypress-io-thailand/understand-stub-spy-apis-that-will-make-your-test-better-than-ever-on-cypress-io-797cb9eb205a#b6ad
 *
 * @param {string} targetURI - The target custom scheme URI
 */
function launchCustomSchemeDeepLink(targetURI) {
  window.location.href = targetURI;
}

/**
 * Function that run on every page load (including InstantClick redirects) and
 * is in charge of the setup that runs the following features:
 * - addEventListener to dismiss the banner when users tap on X button
 * - When the user lands in "/r/mobile"
 *   - Timeout that presents the fallback page if couldn't seamless deep link
 *   - Setup the correct fallback button links based on platform (iOS/Android)
 */
function initializeRuntimeBanner() {
  // This will provide the dismiss functionality for the Runtime Banner
  const bannerDismiss = document.querySelector('.runtime-banner__dismiss');
  if (bannerDismiss) {
    bannerDismiss.addEventListener('click', handleDismissRuntimeBanner);
  }

  // If the "Install now"/"Try again" buttons exist in the DOM it means we are
  // trying to deep link into the mobile app after being redirected by the
  // Runtime Banner itself (the browser is currently in `/r/mobile`)
  const installNowButton = document.getElementById('link-to-mobile-install');
  const retryButton = document.getElementById('link-to-mobile-install-retry');
  if (!installNowButton || !retryButton) {
    return;
  }
  // Since we were redirected to `/r/mobile` by the Banner itself we can safely
  // dismiss it by re-using the handleDismissRuntimeBanner function
  handleDismissRuntimeBanner();

  // The target path comes in via GET request query params
  const urlParams = new URLSearchParams(window.location.search);
  const targetPath = urlParams.get('deep_link');

  // Constants - they will become dynamic (configurable by creators) in upcoming releases
  const FOREM_IOS_SCHEME = 'com.forem.app';
  const FOREM_APP_STORE_URL =
    'https://apps.apple.com/us/app/dev-community/id1439094790';
  const FOREM_GOOGLE_PLAY_URL =
    'https://play.google.com/store/apps/details?id=to.dev.dev_android';

  if (Runtime.currentOS() === 'iOS') {
    // The install now must target Apple's AppStore
    installNowButton.href = FOREM_APP_STORE_URL;

    // We try to deep link directly by launching a custom scheme and populate
    // the retry button in case the user will need it
    const targetLink = `${FOREM_IOS_SCHEME}://${window.location.host}${targetPath}`;
    retryButton.href = targetLink;
    launchCustomSchemeDeepLink(targetLink);
  } else if (Runtime.currentOS() === 'Android') {
    const targetIntent =
      'intent://scan/#Intent;scheme=zxing;package=com.google.zxing.client.android;end';
    retryButton.href = targetIntent;
    installNowButton.href = FOREM_GOOGLE_PLAY_URL;

    // Android support will not be available yet. Links to `/r/mobile` won't be
    // visible in Android browsers. However, as a fallback (safety) measure to
    // avoid having Android users land in this page we redirect them back to the
    // home page. This to avoids users landing in an unsupported (not working
    // for them) page.
    window.location.href = '/';
  }
}
