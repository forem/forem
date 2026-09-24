function initializeFavoritedMarkers() {
  var user = userData();
  if (!user) {
    return;
  }

  var markers = document.querySelectorAll(
    '[data-favorited-marker]:not([data-favorited-initialized])',
  );

  Array.from(markers).forEach(function (marker) {
    if (parseInt(marker.dataset.favoritedByUserId, 10) === user.id) {
      showFavoritedByViewer(marker);
    }
    marker.dataset.favoritedInitialized = true;
  });
}

// private

function showFavoritedByViewer(marker) {
  var theirs = marker.querySelector('[data-favorited-icon="other"]');
  var mine = marker.querySelector('[data-favorited-icon="self"]');
  if (theirs && mine) {
    theirs.classList.add('hidden');
    mine.classList.remove('hidden');
  }
}
