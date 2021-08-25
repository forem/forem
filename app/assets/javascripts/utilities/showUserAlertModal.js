/**
 * HTML ID for modal DOM node
 *
 * @private
 * @constant modalId *
 * @type {string}
 */
const modalId = 'user-alert-modal';

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
  buildModalDiv(text, confirm_text);
  window.Forem.showModal({
    title,
    contentSelector: `#${modalId}`,
    overlay: true,
  });
}
/**
 * Displays a user rate limit alert modal letting the user know what they did that exceeded a rate limit,
 * and gives them links to explain why they must wait
 *
 * @function showRateLimitModal
 * @param {string} action_text Description of the action taken by the user
 * @param {string} next_action_text Description of the next action that can be taken
 *
 * @example
 * showRateLimitModal('Made a comment', 'comment again')
 */
function showRateLimitModal(
  action_text,
  next_action_text,
  timeframe = 'a moment',
) {
  let rateLimitText = buildRateLimitText(
    action_text,
    next_action_text,
    timeframe,
  );
  let rateLimitLink = '/faq';
  showUserAlertModal(
    `Wait ${timeframe}...`,
    rateLimitText,
    'Got it',
    rateLimitLink,
    'Why do I have to wait?',
  );
}
/**
 * Displays the corresponding modal after an error.
 *
 * @function showModalAfterError
 * @param {Object} response The response from the API
 * @param {string} action_text Description of the action taken by the user
 * @param {string} next_action_text Description of the next action that can be taken
 * @param {string} timeframe Description of the time that we need to wait
 *
 * @example
 * showModalAfterError(response, 'made a comment', 'making another comment', 'a moment');
 */
function showModalAfterError(
  response,
  action_text,
  next_action_text,
  timeframe,
) {
  response
    .json()
    .then(function parseError(errorReponse) {
      if (response.status === 429) {
        showRateLimitModal(action_text, next_action_text, timeframe);
      } else {
        showUserAlertModal(
          `Error ${next_action_text}`,
          errorReponse.error,
          'OK',
        );
      }
    })
    .catch(function parseError(error) {
      showUserAlertModal(`Error ${next_action_text}`, 'Server error', 'OK');
    });
}

/**
 * HTML template for modal
 *
 * @private
 * @function getModalHtml
 *
 * @param {string} text The body text to be displayed
 * @param {string} confirm_text Text of the confirmation button
 *
 * @returns {string} HTML for the modal
 */
const getModalHtml = (text, confirm_text) => `
  <div id="${modalId}" hidden>
    <div class="flex flex-col">
      <p class="color-base-70">
        ${text}
      </p>
      <button class="crayons-btn mt-4 ml-auto" type="button" onClick="window.Forem.closeModal()">
        ${confirm_text}
      </button>
    </div>
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
function buildRateLimitText(action_text, next_action_text, timeframe) {
  return `Since you recently ${action_text}, you’ll need to wait ${timeframe} before ${next_action_text}.`;
}

/**
 * Checks for the alert modal, and if it's not present builds and inserts it in the DOM
 *
 * @private
 * @function buildModalDiv
 *
 * @param {string} text The body text to be displayed
 * @param {string} confirm_text Text of the confirmation button
 *
 * @returns {Element} DOM node of the inserted alert modal
 */
function buildModalDiv(text, confirm_text) {
  let modalDiv = document.getElementById(modalId);
  if (!modalDiv) {
    modalDiv = getModal(text, confirm_text);
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
 * @param {string} text The body text to be displayed
 * @param {string} confirm_text Text of the confirmation button
 *
 * @returns {Element} DOM node of alert modal with formatted text
 */
function getModal(text, confirm_text) {
  let wrapper = document.createElement('div');
  wrapper.innerHTML = getModalHtml(text, confirm_text);
  return wrapper;
}
