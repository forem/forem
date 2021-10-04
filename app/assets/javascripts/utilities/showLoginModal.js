function showLoginModal() {
  window.Forem.showModal({
    title: i18next.t('loginModal.title'),
    contentSelector: '#global-signup-modal',
    overlay: true,
  });
}
