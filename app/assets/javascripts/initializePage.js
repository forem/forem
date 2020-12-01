/*
  global initializeLocalStorageRender, initializeBodyData,
  initializeAllChatButtons, initializeAllTagEditButtons, initializeUserFollowButts,
  initializeBaseTracking, initializeTouchDevice, initializeCommentsPage,
  initializeArticleDate, initializeArticleReactions, initNotifications,
  initializeCommentDate, initializeCommentDropdown, initializeSettings,
  initializeCommentPreview,
  initializeTimeFixer, initializeDashboardSort, initializePWAFunctionality,
  initializeEllipsisMenu, initializeArchivedPostFilter, initializeCreditsPage,
  initializeUserProfilePage, initializeProfileInfoToggle, initializePodcastPlayback,
  initializeVideoPlayback, initializeDrawerSliders, initializeProfileBadgesToggle,
  initializeHeroBannerClose, initializeOnboardingTaskCard, initScrolling,
  nextPage:writable, fetching:writable, done:writable, adClicked:writable,
  initializePaymentPointers, initializeSpecialNavigationFunctionality, initializeBroadcast,
  initializeDateHelpers, initializeColorPicker
*/

function callInitializers() {
  initializeLocalStorageRender();
  initializeBodyData();

  var waitingForDataLoad = setInterval(function wait() {
    if (document.body.getAttribute('data-loaded') === 'true') {
      clearInterval(waitingForDataLoad);
      if (document.body.getAttribute('data-user-status') === 'logged-in') {
        initializeBaseUserData();
        initializeAllChatButtons();
        initializeAllTagEditButtons();
      }
      initializeBroadcast();
      initializeAllFollowButts();
      initializeUserFollowButts();
      initializeReadingListIcons();
      initializeSponsorshipVisibility();
      if (document.getElementById('sidebar-additional')) {
        document.getElementById('sidebar-additional').classList.add('showing');
      }
    }
  }, 1);

  initializeSpecialNavigationFunctionality();
  initializeBaseTracking();
  initializePaymentPointers();
  initializeTouchDevice();
  initializeCommentsPage();
  initializeArticleDate();
  initializeArticleReactions();
  initNotifications();
  initializeCommentDate();
  initializeCommentDropdown();
  initializeSettings();
  initializeCommentPreview();
  initializeTimeFixer();
  initializeDashboardSort();
  initializePWAFunctionality();
  initializeEllipsisMenu();
  initializeArchivedPostFilter();
  initializeCreditsPage();
  initializeUserProfilePage();
  initializeProfileInfoToggle();
  initializeProfileBadgesToggle();
  initializePodcastPlayback();
  initializeVideoPlayback();
  initializeDrawerSliders();
  initializeHeroBannerClose();
  initializeOnboardingTaskCard();
  initializeDateHelpers();
  initializeColorPicker();

  function freezeScrolling(event) {
    event.preventDefault();
  }

  nextPage = 0;
  fetching = false;
  done = false;
  adClicked = false;
  setTimeout(function undone() {
    done = false;
  }, 300);
  if (!initScrolling.called) {
    initScrolling();
  }
}

function initializePage() {
  initializeLocalStorageRender();
  callInitializers();
}
