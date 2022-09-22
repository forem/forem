/* global ahoy */
function showLoginModal(trackingData) {
  window.Forem.showModal({
    title: 'Log in to continue',
    contentSelector: '#global-signup-modal',
    overlay: true,
    onOpen: () => {
      if (trackingData && Object.keys(trackingData).length > 0) {
        document
          .querySelector(
            '#window-modal .js-global-signup-modal__create-account',
          )
          .addEventListener('click', () => ahoyTracking(trackingData));
      }
    },
  });
}

function ahoyTracking(trackingData) {
  ahoy.track('Clicked on Create Account', {
    version: 0.1,
    page: location.href,
    source: 'modal',
    referring_source: trackingData.referring_source,
    trigger: trackingData.trigger,
  });
}
