/* global ahoy */
function showLoginModal(trackingData) {
  window.Forem.showModal({
    title: 'Log in to continue',
    contentSelector: '#global-signup-modal',
    overlay: true,
    onOpen: () => {
      document
        .querySelector('#window-modal .js-global-signup-modal__create-account')
        ?.addEventListener('click', () => ahoyTracking(trackingData));
    },
  });
}

function ahoyTracking(trackingData) {
  ahoy.track('Create Account', {
    page: location.href,
    source: 'modal',
    secondary_source: trackingData?.secondary_source,
    trigger: trackingData?.trigger,
  });
}
