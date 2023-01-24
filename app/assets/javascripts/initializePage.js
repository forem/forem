/*
  global initializeLocalStorageRender, initializeBodyData,
  initializeAllTagEditButtons, initializeUserFollowButts,
  initializeBaseTracking, initializeCommentsPage,
  initializeArticleDate, initializeArticleReactions, initNotifications,
  initializeCommentDate, initializeSettings,
  initializeCommentPreview, initializeRuntimeBanner,
  initializeTimeFixer, initializeDashboardSort,
  initializeArchivedPostFilter, initializeCreditsPage,
  initializeProfileInfoToggle, initializePodcastPlayback,
  initializeVideoPlayback, initializeDrawerSliders, initializeProfileBadgesToggle,
  initializeHeroBannerClose, initializeOnboardingTaskCard, initScrolling,
  nextPage:writable, fetching:writable, done:writable, 
  initializePaymentPointers, initializeBroadcast, initializeDateHelpers
*/

function callInitializers() {
  initializeBaseTracking();
  initializePaymentPointers();
  initializeCommentsPage();
  initializeArticleDate();
  initializeArticleReactions();
  initNotifications();
  initializeCommentDate();
  initializeSettings();
  initializeCommentPreview();
  initializeTimeFixer();
  initializeDashboardSort();
  initializeArchivedPostFilter();
  initializeCreditsPage();
  initializeProfileInfoToggle();
  initializeProfileBadgesToggle();
  initializeDrawerSliders();
  initializeHeroBannerClose();
  initializeOnboardingTaskCard();
  initializeDateHelpers();
}

// This is a helper function that mitigates a race condition happening in JS
// when this intializer runs before `base.jsx` gets to load the
// window.Forem / window.Forem.Runtime utility class we depend on for
// podcast/video playback
function initializeRuntimeDependantFeatures() {
  if (window.Forem && window.Forem.Runtime) {
    // The necessary helper functions are available so we can initialize
    // Podcast/Video playback
    initializePodcastPlayback();
    initializeVideoPlayback();

    // Initialize data-runtime context to the body data-attribute
    document.body.dataset.runtime = window.Forem.Runtime.currentContext();
  } else {
    // window.Forem or window.Forem.Runtime isn't available in the context yet
    // so we need to wait for it to exist. It's loaded here:
    // https://github.com/forem/forem/blob/main/app/javascript/packs/base.jsx#L20
    setTimeout(initializeRuntimeDependantFeatures, 200);
  }
}

function initializePage() {
  initializeLocalStorageRender();
  initializeBodyData();

  var waitingForDataLoad = setInterval(function wait() {
    if (document.body.getAttribute('data-loaded') === 'true') {
      clearInterval(waitingForDataLoad);
      if (document.body.getAttribute('data-user-status') === 'logged-in') {
        initializeBaseUserData();
        initializeAllTagEditButtons();
      }
      initializeBroadcast();
      initializeReadingListIcons();
      initializeDisplayAdVisibility();
      if (document.getElementById('sidebar-additional')) {
        document.getElementById('sidebar-additional').classList.add('showing');
      }

      initializeRuntimeDependantFeatures();
    }
  }, 1);

  callInitializers();

  function freezeScrolling(event) {
    event.preventDefault();
  }

  nextPage = 0;
  fetching = false;
  done = false;
  setTimeout(function undone() {
    done = false;
  }, 300);
  if (!initScrolling.called) {
    initScrolling();
  }
}
