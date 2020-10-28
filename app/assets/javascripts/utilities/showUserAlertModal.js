function showUserAlertModal(title, text, confirm_text, link, link_text) {
  let modalDiv = buildModalDiv(title, text, confirm_text, link, link_text);
  toggleUserAlertModal();
}

function showRateLimitModal(action_text, next_action_text) {
  let rateLimitText = buildRateLimitText(action_text, next_action_text);
  let rateLimitLink = "/faq";
  showUserAlertModal('Wait a Moment...', rateLimitText, 'Got it', rateLimitLink, "Why do I have to wait?")
}

const modalId = 'user-alert-modal';

const modalHTML = (title, text, confirm_text, link, link_text) => `<div id="${modalId}" data-testid="modal-container" class="crayons-modal hidden">
    <div role="dialog" aria-modal="true" class="crayons-modal__box">
      <div class="crayons-modal__box__header">
        <h2>${title}</h2>
          <button class="crayons-btn crayons-btn--ghost crayons-btn--icon" type="button" 
              onClick="toggleUserAlertModal();" aria-label="Close">
            <svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon"
              xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="714d29e78a3867c79b07f310e075e824">
              <title id="714d29e78a3867c79b07f310e075e824">Close</title>
              <path
                d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z">
              </path>
            </svg>
          </button>
      </div>
      <div class="crayons-modal__box__body">
        <p>${text}</p>
        </br>
        <button class="crayons-btn crayons-btn--icon" type="button" onClick="toggleUserAlertModal();">${confirm_text}</button>
        <a href="${link}" onClick="toggleUserAlertModal();">${link_text}</button>
      </div>
    </div>
    <div data-testid="modal-overlay" class="crayons-modal__overlay"></div>
  </div>
`;

function buildRateLimitText(action_text, next_action_text) {
  return `Since you recently ${action_text}, you’ll need to wait a moment before ${next_action_text}.`
}

function toggleUserAlertModal() {
  let modalDiv = document.getElementById(modalId);
  if (modalDiv) {
    modalDiv.classList.toggle('hidden');
  }
}

function buildModalDiv(title, text, confirm_text, link, link_text) {
  let modalDiv = document.getElementById(modalId);
  if (!modalDiv) {
    modalDiv = buildModalHTML(title, text, confirm_text, link, link_text);
    document.body.appendChild(modalDiv);
  }
  return modalDiv;
}

function buildModalHTML(title, text, confirm_text, link, link_text) {
  let wrapper = document.createElement('div');
  wrapper.innerHTML= modalHTML(title, text, confirm_text, link, link_text);
  return wrapper.firstChild;
}
