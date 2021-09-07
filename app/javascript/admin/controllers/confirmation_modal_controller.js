import { Controller } from 'stimulus';
import { adminModal } from '../adminModal';

export default class ConfigController extends Controller {
  activateConfirmationModal(providers) {
    this.configModalAnchorTarget.innerHTML = adminModal({
      title: 'Setup not complete',
      body: this.missingAuthKeysModalBody(providers),
      leftBtnText: 'Continue editing',
      leftBtnAction: 'closeAdminModal',
      rightBtnText: 'Cancel',
      rightBtnAction: 'cancelAuthProviderEnable',
      rightBtnClasses: 'crayons-btn--secondary',
    });
  }

  test() {
    alert('Connected!');
  }
}
