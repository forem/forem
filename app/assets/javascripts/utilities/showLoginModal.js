function showLoginModal(context) {
  window.showModal({
    title: 'Log in to continue',
    contentSelector: '#global-signup-modal',
    overlay: true,
  });
}
