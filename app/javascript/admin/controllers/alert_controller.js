import { Controller } from 'stimulus';

export default class AlertController extends Controller {
  static targets = ['alertZone'];

  closeAlert() {
    this.alertZoneTarget.innerHTML = '';
  }

  alertMarkup({ alertMsg, classes }) {
    return `
      <div
        class="mb-3 crayons-notice ${classes}"
        style="display:flex; justify-content:space-between;">
        <div>${alertMsg}</div>
        <svg
          width="24"
          height="24"
          viewBox="0 0 24 24"
          className="crayons-icon"
          xmlns="http://www.w3.org/2000/svg"
          role="img"
          aria-labelledby="714d29e78a3867c79b07f310e075e824"
          data-action="click->alert#closeAlert"
        >
          <title id="714d29e78a3867c79b07f310e075e824">Close</title>
          <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
        </svg>
      </div>
    `;
  }

  generateErrorAlert(event) {
    const { alertMsg } = event.detail;

    this.alertZoneTarget.innerHTML = this.alertMarkup({
      alertMsg,
      classes: 'crayons-notice--danger',
    });
  }

  generateSuccessAlert(event) {
    const { alertMsg } = event.detail;

    this.alertZoneTarget.innerHTML = this.alertMarkup({
      alertMsg,
      classes: 'crayons-notice--success',
    });
  }
}
