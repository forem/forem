function initializeLocalStorageRender() {
  try {
    var userData = browserStoreCache('get');
    if (userData) {
      document.body.dataset.user = userData;
      initializeBaseUserData();
      initializeReadingListIcons();
      initializeBillboardVisibility();
    }
  } catch (err) {
    browserStoreCache('remove');
  }
}
