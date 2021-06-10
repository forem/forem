import ModalController from './modal_controller';

export default class LandingPageModalController extends ModalController {
  static targets = ['overwrite', 'landingPageCheckbox'];
  static values = {
    alreadyHasLandingPage: Boolean,
  };

  openModal() {
    if (
      this.alreadyHasLandingPageValue &&
      this.landingPageCheckboxTarget.checked
    ) {
      this.toggleModal();
    }
  }

  confirm() {
    this.overwriteTarget.value = true;
    this.closeModal();
  }

  cancel() {
    this.landingPageCheckboxTarget.checked = false;
    this.overwriteTarget.value = false;
    this.closeModal();
  }
}
