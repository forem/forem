import ModalController from './modal_controller';

export default class LandingPageModalController extends ModalController {
  static targets = ['overwrite', 'landingPageCheckbox'];

  openModal() {
    if (this.landingPageCheckboxTarget.checked) {
      this.toggleModal();
    }
  }

  confirm(event) {
    event.preventDefault();

    this.overwriteTarget.value = true;
    this.closeModal();
  }

  cancel(event) {
    event.preventDefault();

    this.landingPageCheckboxTarget.checked = false;
    this.overwriteTarget.value = false;
    this.closeModal();
  }
}
