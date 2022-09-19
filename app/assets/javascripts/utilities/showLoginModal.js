/* global ahoy */
function showLoginModal(trackingData) {
  window.Forem.showModal({
    title: 'Log in to continue',
    contentSelector: '#global-signup-modal',
    overlay: true,
    onOpen: () => {
      const referrer = location.href;
      document
        .querySelector('#window-modal .js-global-signup-modal__create-account')
        .addEventListener('click', () => ahoyTracking(trackingData, referrer));
    },
  });
}

function ahoyTracking(trackingData, referrer) {
  ahoy.track('Clicked on Create Account', {
    page: location.href,
    referrer: referrer,
    source: 'modal',
    secondary_source: trackingData.secondary_source,
    trigger: trackingData.trigger,
  });
}
