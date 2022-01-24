/* global Runtime */

import { h } from 'preact';
import { ButtonNew as Button, Icon } from '@crayons';
import CloseIcon from '@images/x.svg';
import LogoForem from '@images/logo-forem-app.svg';

const BANNER_DISMISS_KEY = 'runtimeBannerDismissed';

function dismissBanner() {
  localStorage.setItem(BANNER_DISMISS_KEY, true);
  removeFromDOM();
}

function removeFromDOM() {
  const container = document.getElementById('runtime-banner-container');
  container?.remove();
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

  // Constants - they will become dynamic (configurable by creators) in upcoming releases
  const FOREM_IOS_SCHEME = 'com.forem.app';
  const FOREM_APP_STORE_URL =
    'https://apps.apple.com/us/app/forem/id1536933197';
  const FOREM_GOOGLE_PLAY_URL =
    'https://play.google.com/store/apps/details?id=to.dev.dev_android';

  if (Runtime.currentOS() === 'iOS') {
    // The install now must target Apple's AppStore
    installNowButton.href = FOREM_APP_STORE_URL;

    // We try to deep link directly by launching a custom scheme and populate
    // the retry button in case the user will need it
    const targetLink = `${FOREM_IOS_SCHEME}://${window.location.host}${targetPath}`;
    retryButton.href = targetLink;
    window.location.href = targetLink;
  } else if (Runtime.currentOS() === 'Android') {
    const targetIntent =
      'intent://scan/#Intent;scheme=com.forem.app;package=com.forem.app;end';
    retryButton.href = targetIntent;
    installNowButton.href = FOREM_GOOGLE_PLAY_URL;

    // Android support isn't available yet. Android users visiting `/r/mobile`
    // will be redirected to the home page so they don't land on a unsupported
    // page until this feature is ready for them.
    window.location.href = '/';
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
    Runtime.currentContext() !== 'Browser-iOS'
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

  const targetPath = `https://${window.location.host}/r/mobile?deep_link=${window.location.pathname}`;
  const targetURL = `https://udl.forem.com/${encodeURIComponent(targetPath)}`;

  return (
    <div class="runtime-banner">
      <a
        href={targetURL}
        class="flex items-center flex-1"
        rel="noopener noreferrer"
      >
        <Icon src={LogoForem} native />
        <div class="flex flex-col pl-3">
          <span>Forem</span>
          <span>Open with the Forem app</span>
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
