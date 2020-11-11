import { Controller } from 'stimulus';

export default class ModalController extends Controller {
  static targets = ['toggle'];

  toggleModal() {
    if (this.toggleTarget) {
      this.toggleTarget.classList.toggle('hidden');
    }
  }
}
