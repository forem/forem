import ModalController from '../controllers/modal_controller';
import { displayErrorAlert, displaySnackbar } from '../messageUtilities';

const confirmationText = (username) =>
  `My username is @${username} and this action is 100% safe and appropriate.`;

export default class ConfirmationModalController extends ModalController {
  static targets = ['itemId', 'username', 'endpoint'];

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
        credentials: 'same-origin',
      });

      const outcome = await response.json();

      if (response.ok) {
        this.removeBadgeAchievement(itemId);
        displaySnackbar(outcome.message);
      } else {
        displayErrorAlert(outcome.error);
      }

      this.closeModal();
    } catch (err) {
      displayErrorAlert(err.message);
    }
  }

  checkConfirmationText() {
    const confirmationMismatchWarning = document.querySelector(
      '#confirmation-modal-root #mismatch-warning',
    );

    const confirmationTextEntry = document.querySelector(
      '#confirmation-modal-root #confirmation-text-field',
    ).value;

    if (confirmationTextEntry == confirmationText(this.usernameValue)) {
      this.closeModal();
      this.sendToEndpoint({
        itemId: this.itemIdValue,
        endpoint: this.endpointValue,
      });
    } else {
      confirmationMismatchWarning.classList.remove('hidden');
    }
  }

  openModal(event) {
    const { itemId, endpoint, username } = event.target.dataset;

    this.itemIdValue = itemId;
    this.usernameValue = username;
    this.endpointValue = endpoint;

    this.toggleModal();
  }
}
