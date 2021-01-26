import { Controller } from 'stimulus';

export default class ModalController extends Controller {
  static classes = ['hidden'];
  static targets = ['toggle'];

  toggleModal() {
    if (this.hasToggleTarget) {
      this.toggleTarget.classList.toggle(this.hiddenClass);
    }
  }
}
