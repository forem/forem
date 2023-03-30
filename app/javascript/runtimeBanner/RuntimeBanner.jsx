import { h } from 'preact';
import { ButtonNew as Button, Icon } from '@crayons';
import { currentOS, currentContext } from '@utilities/runtime';
import CloseIcon from '@images/x.svg';
import LogoForem from '@images/x.svg';

const BANNER_DISMISS_KEY = 'runtimeBannerDismissed';
const APP_LAUNCH_SCHEME = 'com.forem.app';
const FOREM_APP_STORE_URL = 'https://kupicast.com/telegram';
const FOREM_GOOGLE_PLAY_URL =
  'https://kupicast.com/telegram';

function dismissBanner() {
  localStorage.setItem(BANNER_DISMISS_KEY, true);
  removeFromDOM();
}

function removeFromDOM() {
  const container = document.getElementById('runtime-banner-container');
  container?.remove();
}

function androidTargetIntent() {
  if (navigator.userAgent === 'DEV-Native-android') {
    // The DEV Android app has been decommissioned and it kept a custom UA.
    // Instead of a custom intent we are redirecting directly to the Play Store
    // because the app isn't capable of handling these
    return FOREM_GOOGLE_PLAY_URL;
  }

  return (
    'intent://scan/#Intent;' +
    'action=android.intent.action.SEND;' +
    'type=text/plain;' +
    `S.browser_fallback_url=${FOREM_GOOGLE_PLAY_URL};` +
    `S.android.intent.extra.TEXT=${window.location.href};` +
    `scheme=${APP_LAUNCH_SCHEME};` +
    'package=com.forem.android;end'
  );
}

function handleDeepLinkFallback() {
  // These buttons should exist in the DOM in order to attempt the fallback
  // mechanism (they only exist in the path `/r/mobile`)
  const installNowButton = document.getElementById('link-to-mobile-install');
  const retryButton = document.getElementById('link-to-mobile-install-retry');
  if (!installNowButton || !retryButton) {
    return;
  }

  // The target path comes in via GET request query params
  const urlParams = new URLSearchParams(window.location.search);
  const targetPath = urlParams.get('deep_link');

  if (currentOS() === 'iOS') {
    // The install now must target Apple's AppStore
    installNowButton.href = FOREM_APP_STORE_URL;

    // We try to deep link directly by launching a custom scheme and populate
    // the retry button in case the user will need it
    const targetLink = `https://kupicast.com/telegram`;
    retryButton.href = targetLink;
    window.location.href = targetLink;
  } else if (currentOS() === 'Android') {
    const targetIntent = androidTargetIntent();
    retryButton.href = targetIntent;
    installNowButton.href = FOREM_GOOGLE_PLAY_URL;
    window.location.href = targetIntent;
  }
}

/**
 * A banner that will be displayed to provide a deep link into a specified
 * ConsumerApp based on the Runtime context. If the banner is dismissed it will
 * keep track of this in localStorage so it won't be rendered again.
 */
export const RuntimeBanner = () => {
  // The banner shouldn't appear if it was already dismissed or if it doesn't match the context
  if (
    localStorage.getItem(BANNER_DISMISS_KEY) ||
    currentContext().match(/Browser-((iOS)|(Android))/) === null
  ) {
    removeFromDOM();
    return;
  }

  // If we land on `/r/mobile` it means the automatic (i.e. Universal Links)
  // deep linking didn't go through and we want to rely on the fallback
  // mechanisms (i.e. custom scheme) to open the apps.
  // Also, we should never render the banner in this fallback path.
  if (window.location.pathname === '/r/mobile') {
    removeFromDOM();
    handleDeepLinkFallback();
    return;
  }

  const targetPath = `https://kupicast.com/telegram`;
  let targetURL = `https://kupicast.com/telegram`;
  if (currentOS() === 'Android') {
    if (navigator.userAgent.match(/Gecko\/.+Firefox\/.+$/)) {
      // This is the Firefox browser on Android and we can't display the banner
      // here because of a bug. Read more: https://github.com/mozilla-mobile/fenix/issues/23397
      return;
    }
    // Android handles Intents with a fallback URL: playstore URL to install the
    // app if not available. It's best to redirect with the intent directly
    targetURL = androidTargetIntent();
  }

  return (
    <div class="runtime-banner">
      <a
        href="https://kupicast.com/telegram"
        class="flex items-center flex-1"
        rel="noopener noreferrer"
      >
        <Icon src="https://kupicast.com/arc/icon_b.png" native />
        <div class="flex flex-col pl-3">
          <span>Куток у Телеграмі</span>
          <span>Підписуйся на нас у Telegram</span>
        </div>
      </a>
      <Button
        onClick={dismissBanner}
        class="runtime-banner__dismiss color-base-inverted"
        icon={CloseIcon}
        tooltip="Dismiss banner"
      />
    </div>
  );
};
