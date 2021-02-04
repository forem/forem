import { Controller } from 'stimulus';
import { getFocusTrapToggle } from '@utilities/getFocusTrapToggle';

// eslint-disable-next-line no-restricted-syntax
export default class ModalController extends Controller {
  static values = {
    trapAreaId: String,
  };

  connect() {
    this.currentFocusTrapToggle = null;
  }

  toggleModal() {
    if (this.currentFocusTrapToggle) {
      this.currentFocusTrapToggle();
      this.currentFocusTrapToggle = null;
      return;
    }

    this.currentFocusTrapToggle = getFocusTrapToggle(
      `#${this.trapAreaIdValue}`,
    );

    this.currentFocusTrapToggle();
  }
}
