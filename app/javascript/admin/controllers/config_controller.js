import { Controller } from 'stimulus';

export default class ConfigController extends Controller {
  static targets = ['inviteOnlyMode', 'authenticationProviders'];

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
}
