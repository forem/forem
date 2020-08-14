function initSignupModal() {
  if (document.getElementById('global-signup-modal')) {
    document.getElementById('global-signup-modal-bg').onclick = () => {
      document
        .getElementById('global-signup-modal')
        .classList.add('hidden');
      document.body.classList.remove('modal-open');
    };
  }
}

function showModal(context) {
  document.getElementById('global-signup-modal').classList.remove('hidden');
  document.body.classList.add('modal-open');
  initSignupModal();
}
