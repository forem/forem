function showConfirmationEmailModal() {
  window.Forem.showModal({
    title: "Didn't get the email?",
    contentSelector: '#confirm-email-modal',
    overlay: true,
    onOpen: attachHandlers,
  });
}

function attachHandlers() {
  const dismissModalButtons =
    document.getElementsByClassName('js-dismiss-button');

  if (dismissModalButtons.length > 1) {
    dismissModalButtons[1].addEventListener(
      'click',
      hideConfirmationEmailModal,
    );
  }
}

function hideConfirmationEmailModal(event) {
  event.preventDefault();
  window.Forem.closeModal();
}

const confirmationButton = document.getElementsByClassName(
  'js-confirmation-button',
)[0];
confirmationButton.addEventListener('click', showConfirmationEmailModal);
