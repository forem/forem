import { Controller } from 'stimulus';

// Wraps the Preact Snackbar component into a Stimulus controller
export default class ErrorController extends Controller {
  static targets = ['errorZone'];

  generateErrorAlert(event) {
    const { errMsg } = event.detail;

    this.errorZoneTarget.innerHTML = `<div class="crayons-notice crayons-notice--danger mb-3">${errMsg}</div>`;
  }
}
