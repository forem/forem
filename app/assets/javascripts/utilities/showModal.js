function showModal(context, activatorSelector) {
  const toggleSignupModal = window.getFocusTrapToggle(
    '#global-signup-modal',
    activatorSelector,
  );

  toggleSignupModal();
  document.body.classList.add('modal-open');

  if (document.getElementById('global-signup-modal')) {
    document.getElementsByClassName(
      'authentication-modal__close-btn',
    )[0].onclick = () => {
      toggleSignupModal();
      document.body.classList.remove('modal-open');
    };
  }
}
