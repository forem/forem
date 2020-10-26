const modalId = 'user-alert-modal';

function showUserAlertModal() {
  let modalDiv = buildModalDiv();
  toggleUserAlertModal();
}

function toggleUserAlertModal() {
  let modalDiv = document.getElementById(modalId);
  if (modalId) {
    modalDiv.classList.toggle('hidden');
  }
}

function buildModalDiv() {
  let modalDiv = document.getElementById(modalId);
  if (!modalDiv) {
    modalDiv = buildModalHTML("Sample Modal", "This is my sample modal dialog box");
    document.body.appendChild(modalDiv);
  }
  return modalDiv;
}


function buildModalHTML(title, text) {
  let wrapper = document.createElement('div');
  wrapper.innerHTML= `<div id="${modalId}" data-testid="modal-container" class="crayons-modal hidden">
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
        </div>
      </div>
      <div data-testid="modal-overlay" class="crayons-modal__overlay"></div>
    </div>
  `;
  return wrapper.firstChild;
}
