import { Controller } from 'stimulus';
import { adminModal } from '../adminModal';
import { displaySnackbar } from '../displaySnackbar';

const confirmationText = (username) =>
  `My username is @${username} and this action is 100% safe and appropriate.`;

export default class ConfirmationModalController extends Controller {
  static targets = [
    'confirmationModalAnchor',
    'confirmationTextField',
    'confirmationTextWarning',
  ];

  closeConfirmationModal() {
    this.confirmationModalAnchorTarget.innerHTML = '';
    document.body.style.height = 'inherit';
    document.body.style.overflowY = 'inherit';
  }

  removeBadgeAchievement(id) {
    return document.querySelector(`[data-row-id="${id}"]`).remove();
  }

  async sendToEndpoint({ itemId, endpoint }) {
    try {
      const response = await fetch(`${endpoint}/${itemId}`, {
        method: 'DELETE',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
            ?.content,
        },
        body: JSON.stringify({ id: itemId }),
        credentials: 'same-origin',
      });

      const outcome = await response.json();

      if (response.ok) {
        this.removeBadgeAchievement(itemId);
        displaySnackbar(outcome.message);
      } else {
        displaySnackbar(outcome.error);
      }

      this.closeConfirmationModal();
    } catch (err) {
      displaySnackbar(err.message);
    }
  }

  checkConfirmationText(event) {
    const { itemId, endpoint, username } = event.target.dataset;

    this.confirmationTextFieldTarget.value != confirmationText(username)
      ? this.confirmationTextWarningTarget.classList.remove('hidden')
      : this.sendToEndpoint({ itemId, endpoint });
  }

  confirmationModalBody(username) {
    return `
      <div class="crayons-field">
        <p>To confirm this update, type in the sentence: <br />
        <strong>${confirmationText(username)}</strong></p>
        <div data-confirmation-modal-target="confirmationTextWarning" class="crayons-notice crayons-notice--warning hidden" aria-live="polite">
          The confirmation text does not match.
        </div>
        <input
          type="text"
          data-confirmation-modal-target="confirmationTextField"
          class="crayons-textfield flex-1 mr-2"
          placeholder: "Confirmation text">
      </div>
    `;
  }

  activateConfirmationModal(event) {
    const { itemId, endpoint, username } = event.target.dataset;

    this.confirmationModalAnchorTarget.innerHTML = adminModal({
      title: 'Confirm changes',
      controllerName: 'confirmation-modal',
      closeModalFunction: 'closeConfirmationModal',
      body: this.confirmationModalBody(username),
      leftBtnText: 'Confirm changes',
      leftBtnAction: 'checkConfirmationText',
      rightBtnText: 'Discard changes',
      rightBtnAction: 'closeConfirmationModal',
      rightBtnClasses: 'crayons-btn--secondary',
      leftCustomDataAttr: `data-item-id="${itemId}" data-endpoint="${endpoint}" data-username="${username}"`,
    });
  }
}
