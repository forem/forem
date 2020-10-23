import { Controller } from 'stimulus';

const recaptchaFields = document.querySelector('#recaptchaContainer');
const emailSigninAndLoginCheckbox = document.querySelector(
  '#email-signup-and-login-checkbox',
);
const emailAuthSettingsSection = document.querySelector(
  '#email-auth-settings-section',
);

// eslint-disable-next-line no-unused-vars
const adminConfigModal = (
  title,
  body,
  confirmBtnText,
  confirmBtnAction,
  cancelBtnText,
  cancelBtnAction,
) => `
  <div class="crayons-modal crayons-modal--s absolute">
    <div class="crayons-modal__box">
      <header class="crayons-modal__box__header">
        <h2>${title}</h2>
        <button type="button" class="crayons-btn crayons-btn--icon crayons-btn--ghost">
          <svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
          </svg>
        </button>
      </header>
      <div class="crayons-modal__box__body">
        ${body}
        <div>
          <button
            class="crayons-btn crayons-btn--danger"
            data-action="click->config#${confirmBtnAction}">
            ${confirmBtnText}
          </button>
          <button
            class="crayons-btn crayons-btn--secondary"
            data-action="click->config#${cancelBtnAction}">
            ${cancelBtnText}
          </button>
        </div>
      </div>
    </div>
    <div class="crayons-modal__overlay"></div>
  </div>
`;

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
      recaptchaFields.classList.remove('hidden');
    } else {
      recaptchaFields.classList.add('hidden');
    }
  }

  enableOrEditEmailAuthSettings() {
    event.preventDefault();
    if (this.emailAuthSettingsBtnTarget.dataset.buttonText === 'enable') {
      emailSigninAndLoginCheckbox.checked = true;
    }
    this.emailAuthSettingsBtnTarget.classList.add('hidden');
    emailAuthSettingsSection.classList.remove('hidden');
  }

  hideEmailAuthSettings() {
    event.preventDefault();
    this.emailAuthSettingsBtnTarget.classList.remove('hidden');
    emailAuthSettingsSection.classList.add('hidden');
  }
}
