/* global Runtime */

import { h } from 'preact';
import { useEffect } from 'preact/hooks';

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
  useEffect(() => {
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
  }, []);

  const targetPath = `https://${window.location.host}/r/mobile?deep_link=${window.location.pathname}`;
  const targetURL = `https://udl.forem.com/?r=${encodeURIComponent(
    targetPath,
  )}`;

  return (
    <div class="runtime-banner">
      <a
        href={targetURL}
        class="flex items-center flex-1"
        target="_blank"
        rel="noopener noreferrer"
      >
        <svg
          class="crayons-icon crayons-icon--default"
          width="32"
          height="32"
          viewBox="0 0 32 32"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M16.44 23.363a.5.5 0 0 1 .59.286c.712 1.893 2.765 2.915 4.713 2.393 1.938-.553 3.206-2.465 2.876-4.46a.474.474 0 0 1 .368-.543l1.628-.437a.508.508 0 0 1 .607.35l.008.032c.642 3.416-1.444 6.743-4.778 7.705-3.352.898-6.813-.909-7.933-4.196a.488.488 0 0 1 .31-.63l.032-.009 1.579-.491z"
            fill="#E9F0E8"
          />
          <path
            d="M12.828 11.415a.5.5 0 0 1-.59-.287c-.713-1.893-2.766-2.915-4.713-2.393-1.971.562-3.206 2.465-2.877 4.461a.474.474 0 0 1-.367.543l-1.628.436a.508.508 0 0 1-.607-.35l-.009-.032c-.642-3.416 1.444-6.742 4.779-7.704 3.352-.898 6.812.908 7.933 4.196a.488.488 0 0 1-.31.63l-.032.008-1.58.492z"
            fill="#4CFCA7"
          />
          <path
            d="m22.142 8.509-1.691.453a.508.508 0 0 1-.607-.35l-.692-2.582a.508.508 0 0 1 .35-.607l1.724-.462a.508.508 0 0 0 .35-.606l-.435-1.626a.486.486 0 0 0-.607-.35l-4.269 1.178a.508.508 0 0 0-.35.606l.563 2.105.692 2.582.692 2.582.026.096L19.81 18.7c.068.255.32.427.575.359l1.596-.428a.508.508 0 0 0 .35-.607l-1.597-5.961c-.051-.192.042-.353.234-.405l1.884-.504a.508.508 0 0 0 .35-.607l-.435-1.626c-.086-.319-.37-.482-.625-.413zm2.155-.133a.526.526 0 0 1 .255-.581c.746-.405 1.157-1.301.934-2.13-.222-.83-.993-1.408-1.834-1.354a.463.463 0 0 1-.502-.344l-.436-1.626c-.068-.255.095-.538.342-.638l.064-.017a4.412 4.412 0 0 1 4.92 3.295c.59 2.2-.511 4.476-2.605 5.345a.513.513 0 0 1-.654-.27l-.017-.063-.467-1.617z"
            fill="#FBC1F5"
          />
        </svg>
        <div class="flex flex-col pl-3">
          <span>Forem</span>
          <span>Open with the Forem app</span>
        </div>
      </a>
      <button
        onClick={dismissBanner}
        type="button"
        class="runtime-banner__dismiss crayons-btn crayons-btn--ghost crayons-btn--icon crayons-btn--inverted crayons-btn--s"
      >
        <svg
          class="crayons-icon"
          title="Dismiss banner: Open with the Forem app"
          aria="true"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
        </svg>
      </button>
    </div>
  );
};
