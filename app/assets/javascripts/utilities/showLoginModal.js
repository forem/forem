function showLoginModal() {
  window.Forem.showModal({
    title: 'Log in to continue',
    contentSelector: '#global-signup-modal',
    overlay: true,
  });
}
