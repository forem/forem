/**
 * Displays a general purpose user alert modal with a title, body text, and confirmation button.
 *
 * @function showUserAlertModal
 * @param {string} title The title/heading text to be displayed
 * @param {string} text The body text to be displayed
 * @param {string} confirm_text Text of the confirmation button
 *
 * @example
 * showUserAlertModal('Warning', 'You must wait', 'OK', '/faq/why-must-i-wait', 'Why must I wait?');
 */
function showUserAlertModal(title, text, confirm_text) {
  let modalDiv = buildModalDiv(title, text, confirm_text);
  toggleUserAlertModal();
}
/**
 * Displays a user rate limit alert modal letting the user know what they did that exceeded a rate limit,
 * and gives them links to explain why they must wait
 *
 * @function showUserAlertModal
 * @param {string} action_text Description of the action taken by the user
 * @param {string} next_action_text Description of the next action that can be taken
 *
 * @example
 * showRateLimitModal('Made a comment', 'comment again')
 */
function showRateLimitModal(action_text, next_action_text) {
  let rateLimitText = buildRateLimitText(action_text, next_action_text);
  let rateLimitLink = '/faq';
  showUserAlertModal(
    'Wait a moment...',
    rateLimitText,
    'Got it',
    rateLimitLink,
    'Why do I have to wait?',
  );
}

/**
 * HTML ID for modal DOM node
 *
 * @private
 * @constant modalId *
 * @type {string}
 */
const modalId = 'user-alert-modal';

/**
 * HTML template for modal
 *
 * @private
 * @function getModalHtml
 *
 * @param {string} title The title/heading text to be displayed
 * @param {string} text The body text to be displayed
 * @param {string} confirm_text Text of the confirmation button
 *
 * @returns {string} HTML for the modal
 */
const getModalHtml = (
  title,
  text,
  confirm_text,
) => `<div id="${modalId}" data-testid="modal-container" class="crayons-modal crayons-modal--m hidden">
    <div role="dialog" aria-modal="true" class="crayons-modal__box">
      <div class="crayons-modal__box__header border-b-0 justify-end">
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
      <div class="crayons-modal__box__body pt-0 flex">
        <div class="w-75">
          <h2>
            ${title}
          </h2>
          <p class="color-base-70">
            ${text}
          </p>
          <button class="crayons-btn mt-4" type="button" onClick="toggleUserAlertModal();">
            ${confirm_text}
          </button>
        </div>
      </div>
    </div>
    <div data-testid="modal-overlay" class="crayons-modal__overlay"></div>
  </div>
`;

/**
 * Constructs wording for rate limit modals
 *
 * @private
 * @function buildRateLimitText
 *
 * @param {string} action_text Description of the action taken by the user
 * @param {string} next_action_text Description of the next action that can be taken
 *
 * @returns {string} Formatted body text for a rate limit modal
 */
function buildRateLimitText(action_text, next_action_text) {
  return `Since you recently ${action_text}, you’ll need to wait a moment before ${next_action_text}.`;
}

/**
 * Shows or hides the user alert modal by toggling it's 'hidden' class
 *
 * @private
 * @function toggleUserAlertModal
 *
 */
function toggleUserAlertModal() {
  let modalDiv = document.getElementById(modalId);
  if (modalDiv) {
    modalDiv.classList.toggle('hidden');
  }
}

/**
 * Checks for the alert modal, and if it's not present builds and inserts it in the DOM
 *
 * @private
 * @function buildModalDiv
 *
 * @param {string} title The title/heading text to be displayed
 * @param {string} text The body text to be displayed
 * @param {string} confirm_text Text of the confirmation button
 *
 * @returns {Element} DOM node of the inserted alert modal
 */
function buildModalDiv(title, text, confirm_text) {
  let modalDiv = document.getElementById(modalId);
  if (!modalDiv) {
    modalDiv = getModal(title, text, confirm_text);
    document.body.appendChild(modalDiv);
  }
  return modalDiv;
}

/**
 * Takes template HTML for a modal and creates a DOM node based on supplied arguments
 *
 * @private
 * @function getModal
 *
 * @param {string} title The title/heading text to be displayed
 * @param {string} text The body text to be displayed
 * @param {string} confirm_text Text of the confirmation button
 *
 * @returns {Element} DOM node of alert modal with formatted text
 */
function getModal(title, text, confirm_text) {
  let wrapper = document.createElement('div');
  wrapper.innerHTML = getModalHtml(title, text, confirm_text);
  return wrapper.firstChild;
}
