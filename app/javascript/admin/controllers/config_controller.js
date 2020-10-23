import { Controller } from 'stimulus';

const recaptchaFields = document.querySelector('#recaptchaContainer');
const emailSigninAndLoginCheckbox = document.querySelector(
  '#email-signup-and-login-checkbox',
);
const emailAuthSettingsSection = document.querySelector(
  '#email-auth-settings-section',
);

export default class ConfigController extends Controller {
  static targets = [
    'inviteOnlyMode',
    'authenticationProviders',
    'requireCaptchaForEmailPasswordRegistration',
    'emailAuthSettingsBtn',
  ];

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

  enableOrEditEmailAuthSettings() {
    event.preventDefault();
    emailSigninAndLoginCheckbox.checked = true;
    this.emailAuthSettingsBtnTarget.classList.add('hidden');
    emailAuthSettingsSection.classList.remove('hidden');
  }

  hideEmailAuthSettings() {
    event.preventDefault();
    this.emailAuthSettingsBtnTarget.classList.remove('hidden');
    emailAuthSettingsSection.classList.add('hidden');
  }
}
