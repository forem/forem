import '../shared/preact/preactRuntime';
import 'focus-visible';
import {
  initializeMobileMenu,
  setCurrentPageIconLink,
  initializeMemberMenu,
} from '../topNavigation/utilities';
import { waitOnBaseData } from '../utilities/waitOnBaseData';
import {
  loadMediaPlaybackBundle,
  shouldInitializePodcastPlayback,
} from '../utilities/mediaPlaybackLoader';
import { maybeLoadEventSignupButtons } from '../utilities/eventSignupButtonsLoader';
import { trackCreateAccountClicks } from '@utilities/ahoy/trackEvents';
import { loadCommentTextAreaBundle } from '@utilities/commentTextAreaLoader';
import { showWindowModal, closeWindowModal } from '@utilities/showModal';
import * as Runtime from '@utilities/runtime';
import { initializeSlides } from '../initializers/initializeSlides';
import { revealBillboardPlacement } from './billboardAfterRenderActions';

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

// Reveals requested by server-rendered billboard scripts before this deferred
// pack ran, queued by the stub in layouts/application.html.erb.
const queuedBillboardPlacementReveals =
  window.Forem?.queuedBillboardPlacementReveals || [];
const existingCommentTextArea = window.Forem?.CommentTextArea;
const existingRenderCommentTextArea = window.Forem?.renderCommentTextArea;
const existingCreateEmojiPopup = window.Forem?.createEmojiPopup;
const existingRenderWindowModal = window.Forem?.renderWindowModal;
const existingUnmountWindowModal = window.Forem?.unmountWindowModal;
const existingPostscribe = window.Forem?.postscribe;
const existingInitializePodcastPlayback =
  window.Forem?.initializePodcastPlayback;
const existingInitializeVideoPlayback = window.Forem?.initializeVideoPlayback;

// Namespace for functions which need to be accessed in plain JS initializers
window.Forem = {
  audioInitialized: false,
  CommentTextArea: existingCommentTextArea,
  renderCommentTextArea: existingRenderCommentTextArea,
  createEmojiPopup: existingCreateEmojiPopup,
  renderWindowModal: existingRenderWindowModal,
  unmountWindowModal: existingUnmountWindowModal,
  postscribe: existingPostscribe,
  initializePodcastPlayback: existingInitializePodcastPlayback,
  initializeVideoPlayback: existingInitializeVideoPlayback,
  enhancedCommentTextAreaImport: undefined,
  getEnhancedCommentTextAreaImports() {
    if (!this.enhancedCommentTextAreaImport) {
      this.enhancedCommentTextAreaImport = loadCommentTextAreaBundle().catch(
        (err) => {
          this.enhancedCommentTextAreaImport = undefined;
          throw err;
        },
      );
    }
    return Promise.all([this.enhancedCommentTextAreaImport]);
  },
  initializeEnhancedCommentTextArea: async (originalTextArea) => {
    const parentContainer = originalTextArea?.parentElement;
    if (!parentContainer) {
      return;
    }

    const alreadyInitialized =
      parentContainer.classList.contains('c-autocomplete');

    if (alreadyInitialized) {
      return;
    }

    if (typeof window.Forem.renderCommentTextArea === 'function') {
      window.Forem.renderCommentTextArea(originalTextArea);
      return;
    }

    const [{ renderCommentTextArea }] =
      await window.Forem.getEnhancedCommentTextAreaImports();

    if (typeof renderCommentTextArea === 'function') {
      renderCommentTextArea(originalTextArea);
    }
  },
  showModal: showWindowModal,
  closeModal: () => closeWindowModal(),
  revealBillboardPlacement,
  Runtime,
};

window.initializePodcastPlayback =
  window.initializePodcastPlayback ||
  (() => {
    loadMediaPlaybackBundle().then(({ initializePodcastPlayback }) => {
      initializePodcastPlayback?.();
    });
  });

function maybeInitializeMediaPlayback() {
  const needsVideo = Boolean(document.getElementById('video-player-source'));
  const needsPodcast = shouldInitializePodcastPlayback(Runtime);

  if (!needsVideo && !needsPodcast) {
    return;
  }

  loadMediaPlaybackBundle().then(
    ({ initializePodcastPlayback, initializeVideoPlayback }) => {
      if (needsVideo && document.getElementById('video-player-source')) {
        initializeVideoPlayback?.();
      }
      if (needsPodcast) {
        initializePodcastPlayback?.();
      }
    },
  );
}

queuedBillboardPlacementReveals.forEach(revealBillboardPlacement);

if (document.location.pathname.startsWith('/dashboard')) {
  import('./initializers/initializeDashboardSort').then(
    ({ initializeDashboardSort }) => {
      initializeDashboardSort();
    },
  );
}

maybeInitializeMediaPlayback();
maybeLoadEventSignupButtons();
document.ready.then(() => {
  initializeSlides();
});
function updateSearchPlaceholder() {
  const searchElement = document.getElementById('search-input');
  if (!searchElement) {
    return;
  }
  const articleContainer = document.getElementById('article-show-container');
  if (articleContainer?.dataset?.articleId) {
    searchElement.placeholder = 'Find related posts...';
  } else {
    searchElement.placeholder = 'Search...';
  }
}

InstantClick.on('change', () => {
  if (document.location.pathname.startsWith('/dashboard')) {
    import('./initializers/initializeDashboardSort').then(
      ({ initializeDashboardSort }) => {
        initializeDashboardSort();
      },
    );
  }

  maybeInitializeMediaPlayback();
  maybeLoadEventSignupButtons();
  initializeSlides();
  trackCreateAccountClicks('sidebar-wrapper-left');

  if (window.instgrm?.Embeds?.process) {
    window.instgrm.Embeds.process();
  }

  updateSearchPlaceholder();
});

InstantClick.on('restore', updateSearchPlaceholder);

// Initialize data-runtime context to the body data-attribute
document.body.dataset.runtime = window.Forem.Runtime.currentContext();

function getPageEntries() {
  return Object.entries({
    'notifications-index': document.getElementById('notifications-link'),
    'moderations-index': document.getElementById('moderation-link'),
    'articles_search-index': document.getElementById('search-link'),
  });
}

/**
 * Initializes the left hand side hamburger menu
 */
function initializeNav() {
  const pageContent = document.getElementById('page-content');
  if (!pageContent) {
    return;
  }
  const { currentPage } = pageContent.dataset;
  const menuTriggers = [
    ...document.querySelectorAll('.js-hamburger-trigger, .hamburger a'),
  ];

  setCurrentPageIconLink(currentPage, getPageEntries());
  initializeMobileMenu(menuTriggers);
}

const memberMenu = document.getElementById('crayons-header__menu');
const menuNavButton = document.getElementById('member-menu-button');

if (memberMenu) {
  initializeMemberMenu(memberMenu, menuNavButton);
}

/**
 * Fetches the html for the navigation_links from an endpoint and dynamically inserts it in the DOM.
 */
async function getNavigation() {
  const placeholderElement = document.getElementsByClassName(
    'js-navigation-links-container',
  )[0];

  if (placeholderElement.innerHTML.trim() === '') {
    const response = await window.fetch(`/async_info/navigation_links`);
    const htmlContent = await response.text();

    const generatedElement = document.createElement('div');
    generatedElement.innerHTML = htmlContent;

    placeholderElement.appendChild(generatedElement);
  }
}

// Initialize when asset pipeline (sprockets) initializers have executed
waitOnBaseData()
  .then(() => {
    InstantClick.on('change', () => {
      initializeNav();
    });
    InstantClick.on('restore', () => {
      initializeNav();
    });

    if (Runtime.currentMedium() === 'ForemWebView') {
      // Dynamic import of the namespace
      import('../mobile/foremMobile.js').then((module) => {
        // Load the namespace
        window.ForemMobile = module.foremMobileNamespace();
        // Run the first session
        window.ForemMobile.userSessionBroadcast();
      });
    }
  })
  .catch((error) => {
    Honeybadger.notify(error);
  });

// we need to call initializeNav here for the initial page load
initializeNav();

document.ready.then(() => {
  setTimeout(() => {
    history.scrollRestoration = 'manual';
  }, 0);

  const hamburgerTrigger = document.getElementsByClassName(
    'js-hamburger-trigger',
  )[0];
  hamburgerTrigger.addEventListener('click', getNavigation);

  // Dynamically load Search.js on hover or keyboard focus of #search-input.
  const searchInput = document.querySelector('#search-input');
  const searchScriptMeta = document.querySelector('meta[name="search-script"]');
  if (searchInput && searchScriptMeta) {
    const ensureSearchScriptLoaded = () => {
      const scriptPath = searchScriptMeta.getAttribute('content');
      if (
        scriptPath &&
        !document.querySelector(`script[src="${scriptPath}"]`)
      ) {
        const script = document.createElement('script');
        script.src = scriptPath;
        script.defer = true;
        script.onerror = () => {
          script.remove();
        };
        document.head.appendChild(script);
      }
    };
    searchInput.addEventListener('mouseenter', ensureSearchScriptLoaded);
    searchInput.addEventListener('focus', ensureSearchScriptLoaded);
  }
});

trackCreateAccountClicks('authentication-hamburger-actions');
trackCreateAccountClicks('authentication-top-nav-actions');
trackCreateAccountClicks('comments-locked-cta');
trackCreateAccountClicks('sidebar-wrapper-left');
