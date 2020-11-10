import { Controller } from 'stimulus';

export default class ModalController extends Controller {
  toggleModal() {
    let modal = document.getElementById(this.data.get('target-id'));
    if (modal) {
      modal.classList.toggle('hidden');
    }
  }
}
