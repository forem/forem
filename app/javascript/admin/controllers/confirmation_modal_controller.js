import { Controller } from 'stimulus';
import { adminModal } from '../adminModal';

const confirmationText = (username) =>
  `My username is @${username} and this action is 100% safe and appropriate.`;

export default class ConfirmationModalController extends Controller {
  static targets = ['confirmationModalAnchor', 'confirmationTextField'];

  closeConfirmationModal() {
    this.confirmationModalAnchorTarget.innerHTML = '';
    document.body.style.height = 'inherit';
    document.body.style.overflowY = 'inherit';
  }

  async sendToEndpoint({ itemId }) {
    try {
      const body = { id: itemId };
      const response = await fetch(
        `/admin/content_manager/badge_achievements/${itemId}`,
        {
          method: 'DELETE',
          headers: {
            Accept: 'application/json',
            'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
              ?.content,
          },
          body,
          credentials: 'same-origin',
        },
      );

      const outcome = await response.json();

      // eslint-disable-next-line no-console
      console.log(outcome);
    } catch (err) {
      // eslint-disable-next-line no-console
      console.log(err.message);
    }
  }

  checkConfirmationText(event) {
    const { itemId, endpoint, username } = event.target.dataset;

    if (this.confirmationTextFieldTarget.value != confirmationText(username)) {
      alert('The confirmation text does not match; please try again.');
      return;
    }
    this.sendToEndpoint({ itemId, endpoint });
  }

  confirmationModalBody(username) {
    return `
      <div class="crayons-field">
        <p>To confirm this update, type in the sentence: <br />
        <strong>${confirmationText(username)}</strong></p>
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
