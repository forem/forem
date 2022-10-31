import { closeWindowModal, showWindowModal } from '@utilities/showModal';

/**
 * A function to generate the HTML for a Crayons modal within the /admin/ space.
 *
 * @function adminModal
 * @param {Object} modalProps Properties of the Modal
 * @param {string} modalProps.title The title of the modal.
 * @param {function} modalProps.closeModalFunction The name of the function that closes the modal.
 * @param {string} modalProps.body The modal's content. May use HTML tags for styling.
 * @param {string} modalProps.leftBtnText The text for the modal's left button.
 * @param {function} modalProps.leftBtnAction The function that fires when left button is clicked.
 * @param {string} modalProps.rightBtnText The text for the modal's right button.
 * @param {function} modalProps.rightBtnAction The function that fires when right button is clicked.
 * @param {string} modalProps.leftBtnClasses Classes applied to left button.
 * @param {string} modalProps.rightBtnClasses Classes applied to right button.
 * @param {string} modalProps.leftCustomDataAttr A custom data attribute for the left button.
 * @param {string} modalProps.rightCustomDataAttr A custom data attribute for the right button.
 */
export const adminModal = function ({
  title,
  closeModalFunction,
  body,
  leftBtnText,
  leftBtnAction,
  rightBtnText,
  rightBtnAction,
  leftBtnClasses,
  rightBtnClasses,
  leftCustomDataAttr = null,
  rightCustomDataAttr = null,
}) {
  const content = `
    <div class="admin-modal-content grid gap-4">
      ${body}
      <div class="crayons-btn-actions">
        <button
          id="left-btn"
          class="crayons-btn ${leftBtnClasses}"
          ${leftCustomDataAttr}>
          ${leftBtnText}
        </button>
        <button
          id="right-btn"
          class="crayons-btn ${rightBtnClasses}"
          ${rightCustomDataAttr}>
          ${rightBtnText}
        </button>
      </div>
    </div>
  `;

  return showWindowModal({
    document: window.document,
    title,
    modalContent: content,
    size: 'small',
    onOpen: () => {
      window.document
        .getElementById(`left-btn`)
        .addEventListener('click', (event) => {
          closeWindowModal();
          leftBtnAction(event);
        });

      window.document
        .getElementById(`right-btn`)
        .addEventListener('click', (event) => {
          closeWindowModal();
          rightBtnAction(event);
        });

      window.document
        .querySelector(`.crayons-modal__dismiss`)
        .addEventListener('click', (event) => {
          closeModalFunction(event);
        });
    },
  });
};
