import ModalController from './modal_controller';

export default class LandingPageModalController extends ModalController {
  static targets = ['landingPageCheckbox'];

  openModal() {
    if (this.landingPageCheckboxTarget.checked) {
      this.toggleModal();
    }
  }

  confirm(event) {
    event.preventDefault();

    this.closeModal();
  }

  cancel(event) {
    event.preventDefault();

    this.landingPageCheckboxTarget.checked = false;
    this.closeModal();
  }
}
