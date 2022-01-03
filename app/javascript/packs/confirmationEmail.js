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

  // With the nature of how the modals are implemented,
  // it duplicates the content of #confirm-email-modal and
  // adds it to the window within #window-modal. This means
  // that there are two of the same elements in the DOM,
  // hence we use the last one that is added to the DOM.
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
