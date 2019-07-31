function showModal(context) {
  document.getElementById('global-signup-modal').style.display = 'block';
  document.getElementById('global-signup-modal').classList.add('showing');
  document.getElementsByTagName('body')[0].classList.add('modal-open');
  initSignupModal();
}

function initSignupModal() {
  if (document.getElementById('global-signup-modal')) {
    document.getElementById('global-signup-modal-bg').onclick = function() {
      document.getElementById('global-signup-modal').style.display = 'none';
      document
        .getElementById('global-signup-modal')
        .classList.remove('showing');
      document.getElementsByTagName('body')[0].classList.remove('modal-open');
    };
  }
}
