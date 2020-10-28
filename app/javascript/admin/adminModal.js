/**
 * A function to generate the HTML for a Crayons modal within the /admin/ space.
 *
 * @function adminModal
 * @param {string} title The title of the modal.
 * @param {string} body The modal's content. May use HTML tags for styling.
 * @param {string} confirmBtnText The text for the modal's "Confirm" button.
 * @param {string} confirmBtnAction The function that fires when "Confirm" button is clicked.
 * @param {string} cancelBtnText The text for the modal's "Cancel" button.
 * @param {string} cancelBtnAction The function that fires when "Cancel" button is clicked.
 */
const adminModal = (
  title,
  body,
  confirmBtnText,
  confirmBtnAction,
  cancelBtnText,
  cancelBtnAction,
) => `
  <div class="crayons-modal crayons-modal--s absolute">
    <div class="crayons-modal__box">
      <header class="crayons-modal__box__header">
        <p class="fw-bold fs-l">${title}</p>
        <button type="button" class="crayons-btn crayons-btn--icon crayons-btn--ghost" data-action="click->config#closeAdminConfigModal">
          <svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
          </svg>
        </button>
      </header>
      <div class="crayons-modal__box__body">
        ${body}
        <div class="mt-6">
          <button
            class="crayons-btn crayons-btn--danger"
            data-action="click->config#${confirmBtnAction}">
            ${confirmBtnText}
          </button>
          <button
            class="crayons-btn crayons-btn--secondary"
            data-action="click->config#${cancelBtnAction}">
            ${cancelBtnText}
          </button>
        </div>
      </div>
    </div>
    <div class="crayons-modal__overlay"></div>
  </div>
`;

export default adminModal;
