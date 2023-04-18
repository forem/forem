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
export function showUserAlertModal(title, text, confirm_text) {
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
 * @param {string} element Description of the element that throw the error
 * @param {string} action_ing The -ing form of the action taken by the user
 * @param {string} action_past The past tense of the action taken by the user
 * @param {string} timeframe Description of the time that we need to wait
 *
 * @example
 * showRateLimitModal('Made a comment', 'comment again')
 */
function showRateLimitModal({
  element,
  action_ing,
  action_past,
  timeframe = 'a moment',
}) {
  const rateLimitText = buildRateLimitText({
    element,
    action_ing,
    action_past,
    timeframe,
  });
  const rateLimitLink = '/faq';
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
 * @param {string} element Description of the element that throw the error
 * @param {string} action_ing The -ing form of the action taken by the user
 * @param {string} action_past The past tense of the action taken by the user
 * @param {string} timeframe Description of the time that we need to wait
 *
 * @example
 * showModalAfterError(response, 'made a comment', 'making another comment', 'a moment');
 */
export function showModalAfterError({
  response,
  element,
  action_ing,
  action_past,
  timeframe = 'a moment',
}) {
  response
    .json()
    .then((errorResponse) => {
      if (response.status === 429) {
        showRateLimitModal({
          element,
          action_ing,
          action_past,
          timeframe,
        });
      } else {
        showUserAlertModal(
          `Error ${action_ing} ${element}`,
          `Your ${element} could not be ${action_past} due to an error: ${errorResponse.error}`,
          'OK',
        );
      }
    })
    .catch(() => {
      showUserAlertModal(
        `Error ${action_ing} ${element}`,
        `Your ${element} could not be ${action_past} due to a server error`,
        'OK',
      );
    });
}

/**
 * Constructs wording for rate limit modals
 *
 * @private
 * @function buildRateLimitText
 *
 * @param {string} element Description of the element that throw the error
 * @param {string} action_ing The -ing form of the action taken by the user
 * @param {string} action_past The past tense of the action taken by the user
 * @param {string} timeframe Description of the time that we need to wait
 *
 * @returns {string} Formatted body text for a rate limit modal
 */
export function buildRateLimitText({
  element,
  action_ing,
  action_past,
  timeframe,
}) {
  return `Since you recently ${action_past} a ${element}, you’ll need to wait ${timeframe} before ${action_ing} another ${element}.`;
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
export const getModalHtml = (text, confirm_text) => `
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
  } else {
    modalDiv.outerHTML = getModal(text, confirm_text).outerHTML;
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
export function getModal(text, confirm_text) {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = getModalHtml(text, confirm_text);
  return wrapper;
}
