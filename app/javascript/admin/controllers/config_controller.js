import { Controller } from 'stimulus';

const recaptchaFields = document.querySelector('#recaptchaContainer');

export default class ConfigController extends Controller {
  static targets = ['inviteOnlyMode', 'authenticationProviders', 'requireCaptchaForEmailPasswordRegistration'];

  disableAuthenticationOptions() {
    if (this.inviteOnlyModeTarget.checked) {
      this.authenticationProvidersTarget.disabled = true;
      document.querySelector(
        'button[data-id=site_config_authentication_providers]',
      ).disabled = true;
    } else {
      this.authenticationProvidersTarget.disabled = false;
      document.querySelector(
        'button[data-id=site_config_authentication_providers]',
      ).disabled = false;
    }
  }

  toggleGoogleRecaptchaFields() {
    if (this.requireCaptchaForEmailPasswordRegistrationTarget.checked) {
      recaptchaFields.classList.remove('collapse');
    } else {
      recaptchaFields.classList.add('collapse');
    }
  }
}
