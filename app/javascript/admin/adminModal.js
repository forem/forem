/**
 * A function to generate the HTML for a Crayons modal within the /admin/ space.
 *
 * @function adminModal
 * @param {string} title The title of the modal.
 * @param {string} body The modal's content. May use HTML tags for styling.
 * @param {string} firstBtnText The text for the modal's first button.
 * @param {string} firstBtnAction The function that fires when first button is clicked.
 * @param {string} secondBtnText The text for the modal's second button.
 * @param {string} secondBtnAction The function that fires when second button is clicked.
 * @param {string} firstBtnClasses Classes applied to first button.
 * @param {string} secondBtnClasses Classes applied to second button.
 * @param {string} customAttr A custom data attribute name. Will be apprended to the "data-" part.
 * @param {string} customAttrValue The value of the custom attribute "customAttr".
 */
const adminModal = (
  title,
  body,
  firstBtnText,
  firstBtnAction,
  secondBtnText,
  secondBtnAction,
  firstBtnClasses = 'crayons-btn crayons-btn--danger',
  secondBtnClasses = 'crayons-btn crayons-btn--secondary',
  customAttr = null,
  customAttrValue = null,
) => `
  <div class="crayons-modal crayons-modal--s">
    <div class="crayons-modal__box">
      <header class="crayons-modal__box__header">
        <p class="fw-bold fs-l">${title}</p>
        <button type="button" class="crayons-btn crayons-btn--icon crayons-btn--ghost" data-action="click->config#closeAdminModal">
          <svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
          </svg>
        </button>
      </header>
      <div class="crayons-modal__box__body flex flex-col gap-4">
        ${body}
        <div class="flex gap-2">
          <button
            class="${firstBtnClasses}"
            data-action="click->config#${firstBtnAction}"
            data-${customAttr}="${customAttrValue}">
            ${firstBtnText}
          </button>
          <button
            class="${secondBtnClasses}"
            data-action="click->config#${secondBtnAction}">
            ${secondBtnText}
          </button>
        </div>
      </div>
    </div>
    <div class="crayons-modal__overlay"></div>
  </div>
`;

export default adminModal;
