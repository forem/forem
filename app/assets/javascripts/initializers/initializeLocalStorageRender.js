function initializeLocalStorageRender() {
  try {
    var userData = browserStoreCache('get');
    if (userData) {
      document.body.dataset.user = userData;
      initializeBaseUserData();
      initializeReadingListIcons();
      initializeAllFollowButts();
      initializeSponsorshipVisibility();
    }
  } catch (err) {
    browserStoreCache('remove');
  }
}
