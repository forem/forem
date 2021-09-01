import { Controller } from 'stimulus';

export default class ConsumerAppController extends Controller {
  static targets = ['platform', 'teamId'];

  connect() {
    this.checkPlatform();
  }

  checkPlatform() {
    if (this.platformTarget.value === 'ios') {
      this.teamIdTarget.classList.remove('hidden');
    } else {
      this.teamIdTarget.classList.add('hidden');
    }
  }
}
