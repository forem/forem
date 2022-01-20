import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';
import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';
import { initializeDropdown } from '../utilities/dropdownUtils';
import { embedGists } from '../utilities/gist';

/* global Runtime */

const animatedImages = document.querySelectorAll('[data-animated="true"]');
if (animatedImages.length > 0) {
  import('freezeframe').then(({ default: Freezeframe }) => {
    const freezeframes = [];

    const handleMutationsForReadyState = (_mutationList, observer) => {
      // Wait until freezeframe has finished initializing
      const initializedFrames = document.querySelectorAll(
        '.ff-container.ff-ready',
      );

      if (initializedFrames.length === freezeframes.length) {
        observer.disconnect();

        const okWithMotion = window.matchMedia(
          '(prefers-reduced-motion: no-preference)',
        ).matches;

        freezeframes.forEach((ff) => {
          if (okWithMotion) {
            ff.start();
          }

          // Freezeframe doesn't allow gifs to be stopped by keyboard press, so we add a button to handle it
          const ffWrapper = ff.items[0]['$container'];

          render(
            <button
              aria-label="Toggle animation playback"
              aria-pressed={!okWithMotion}
              className="ff-button"
              onClick={(e) => {
                ff.toggle();
                const { target } = e;
                const isPressed =
                  target.getAttribute('aria-pressed') === 'true';
                target.setAttribute('aria-pressed', !isPressed);
              }}
            >
              toggle
            </button>,
            ffWrapper,
          );
        });
      }
    };

    const readyWatcher = new MutationObserver(handleMutationsForReadyState);
    readyWatcher.observe(document.querySelector('main'), {
      subtree: true,
      attributes: true,
      attributeFilter: ['class'],
    });

    // Remove the surrounding links for the image, so it can be clicked to play/pause
    for (const image of animatedImages) {
      image.closest('a').outerHTML = image.outerHTML;

      freezeframes.push(
        new Freezeframe({
          selector: `img[src="${image.getAttribute('src')}"]`,
          responsive: false,
          trigger: 'click',
        }),
      );
    }
  });
}

const fullscreenActionElements = document.getElementsByClassName(
  'js-fullscreen-code-action',
);

if (fullscreenActionElements) {
  addFullScreenModeControl(fullscreenActionElements);
}

// The Snackbar for the article page
const snackZone = document.getElementById('snack-zone');
if (snackZone) {
  render(<Snackbar lifespan={3} />, snackZone);
}

// eslint-disable-next-line no-restricted-globals
top.addSnackbarItem = addSnackbarItem;

// Dropdown accessibility
function hideCopyLinkAnnouncerIfVisible() {
  document.getElementById('article-copy-link-announcer').hidden = true;
}

// Initialize the share options
const shareDropdownButton = document.getElementById('article-show-more-button');

if (shareDropdownButton.dataset.initialized !== 'true') {
  if (Runtime.isNativeAndroid('shareText')) {
    // Android native apps have enhanced sharing capabilities for Articles and don't use our standard dropdown
    shareDropdownButton.addEventListener('click', () =>
      AndroidBridge.shareText(location.href),
    );
  } else {
    const { closeDropdown } = initializeDropdown({
      triggerElementId: 'article-show-more-button',
      dropdownContentId: 'article-show-more-dropdown',
      onClose: hideCopyLinkAnnouncerIfVisible,
    });

    // We want to close the dropdown on link select (since they open in a new tab)
    document
      .querySelectorAll('#article-show-more-dropdown [href]')
      .forEach((link) => {
        link.addEventListener('click', (event) => {
          closeDropdown(event);
        });
      });
  }

  shareDropdownButton.dataset.initialized = 'true';
}

// Initialize the copy to clipboard functionality
function showAnnouncer() {
  document.getElementById('article-copy-link-announcer').hidden = false;
}

function copyArticleLink() {
  const postUrlValue = document
    .getElementById('copy-post-url-button')
    .getAttribute('data-postUrl');
  Runtime.copyToClipboard(postUrlValue).then(() => {
    showAnnouncer();
  });
}
document
  .getElementById('copy-post-url-button')
  ?.addEventListener('click', copyArticleLink);

// Comment Subscription
getCsrfToken().then(async () => {
  const { user = null, userStatus } = document.body.dataset;
  const root = document.getElementById('comment-subscription');
  const isLoggedIn = userStatus === 'logged-in';

  try {
    const {
      getCommentSubscriptionStatus,
      setCommentSubscriptionStatus,
      CommentSubscription,
    } = await import('../CommentSubscription');

    const { articleId } = document.getElementById('article-body').dataset;

    let subscriptionType = 'not_subscribed';

    if (isLoggedIn && user !== null) {
      ({ config: subscriptionType } = await getCommentSubscriptionStatus(
        articleId,
      ));
    }

    const subscriptionRequestHandler = async (type) => {
      const message = await setCommentSubscriptionStatus(articleId, type);

      addSnackbarItem({ message, addCloseButton: true });
    };

    render(
      <CommentSubscription
        subscriptionType={subscriptionType}
        positionType="static"
        onSubscribe={subscriptionRequestHandler}
        onUnsubscribe={subscriptionRequestHandler}
        isLoggedIn={isLoggedIn}
      />,
      root,
    );
  } catch (e) {
    document.getElementById('comment-subscription').innerHTML =
      '<p className="color-accent-danger">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
  }
});

const targetNode = document.querySelector('#comments');
targetNode && embedGists(targetNode);
