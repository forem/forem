import { Controller } from 'stimulus';
import { getFocusTrapToggle } from '../../shared/components/getFocusTrapToggle';

export default class ModalController extends Controller {
  static values = {
    trapAreaId: String,
    activatorId: String,
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
      `#${this.activatorIdValue}`,
    );

    this.currentFocusTrapToggle();
  }
}
