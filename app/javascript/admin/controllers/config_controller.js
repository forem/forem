/* global jQuery */
import { Controller } from '@hotwired/stimulus';
import { adminModal } from '../adminModal';
import { displaySnackbar } from '../messageUtilities';

const recaptchaFields = document.getElementById('recaptchaContainer');
const emailRegistrationCheckbox = document.getElementById(
  'email-registration-checkbox',
);
const emailAuthSettingsSection = document.getElementById(
  'email-auth-settings-section',
);
const emailAuthModalTitle = 'Disable Email address registration';

const emailAuthModalBody = `
  <p>If you disable Email address as a registration option, people cannot create an account with their email address.</p>
  <p>However, people who have already created an account using their email address can continue to login.</p>`;

export default class ConfigController extends Controller {
  static targets = [
    'authenticationProviders',
    'authSectionForm',
    'collectiveNoun',
    'configModalAnchor',
    'emailAuthSettingsBtn',
    'enabledIndicator',
    'inviteOnlyMode',
    'requireCaptchaForEmailPasswordRegistration',
  ];

  connect() {
    const element = document.querySelector(
      `${window.location.hash} .card-body`,
    );
    element?.classList.add('show');
  }

  // GENERAL FUNCTIONS START

  // This is a bit of hack because we have to deal with Bootstrap used inline, jQuery and Stimulus  :-/
  // NOTE: it'd be best to rewrite this as a reusable "toggle" element in Stimulus without using jQuery + Bootstrap
  toggleAccordionButtonLabel(event) {
    const $target = jQuery(event.target);
    const $container = $target.parent();

    const text = $target.text();

    if ($container) {
      const show = $container.attr('aria-expanded') === 'true';

      if (show) {
        $target.text(text.replace(/Hide/i, 'Show'));
      } else {
        $target.text(text.replace(/Show/i, 'Hide'));
      }
    }
  }

  disableTargetField(event) {
    const targetElementName = event.target.dataset.disableTarget;
    const targetElement = this[`${targetElementName}Target`];
    const newValue = event.target.checked;
    targetElement.disabled = newValue;

    // Disable the button generated by ERB for select tags
    if (targetElement.nodeName === 'SELECT') {
      const snakeCaseName = targetElementName.replace(
        /[A-Z]/g,
        (letter) => `_${letter.toLowerCase()}`,
      );
      document.querySelector(
        `button[data-id=settings_${snakeCaseName}]`,
      ).disabled = newValue;
    }
  }

  closeAdminModal() {
    // per forem/internalEngineering#336, need to short-circuit the
    // "Update Settings" button submit action; chose not to
    // define Target on actual "Update" button (since it's a partial).
    // The Target is defined on the Authentication form, and that section's
    // "Update" button is queried.
    const submitBtn = this.authSectionFormTarget.querySelector(
      'input[type="submit"]',
    );

    this.configModalAnchorTarget.innerHTML = '';
    document.body.style.height = 'inherit';
    document.body.style.overflowY = 'inherit';

    if (submitBtn.hasAttribute('disabled')) {
      submitBtn.removeAttribute('disabled');
    }
  }

  positionModalOnPage() {
    if (document.getElementsByClassName('crayons-modal')[0]) {
      document.body.style.height = '100vh';
      document.body.style.overflowY = 'hidden';
    }
  }

  async updateConfigurationSettings(event) {
    event.preventDefault();
    let errored = false;

    try {
      const body = new FormData(event.target);
      const response = await fetch(event.target.action, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
            ?.content,
        },
        body,
        credentials: 'same-origin',
      });

      const outcome = await response.json();

      displaySnackbar(outcome.message ?? outcome.error);
    } catch (err) {
      errored = true;
      displaySnackbar(err.message);
    } finally {
      // Only update the site logo in the header if the new logo is uploaded successfully.
      if (!errored && event.target.elements.settings_general_logo) {
        this.updateLogo();
      }
    }
  }

  /**
   * Updates the site logo in the header with the same URL as the preview logo.
   */
  updateLogo() {
    const previewLogo = document.querySelector(
      '#logo-upload-preview .site-logo__img',
    );

    if (!previewLogo) {
      return;
    }

    for (const logo of document.querySelectorAll('.site-logo__img')) {
      if (logo !== previewLogo) {
        logo.src = previewLogo.src;
      }
    }
  }

  // GENERAL FUNCTIONS END

  // EMAIL AUTH FUNCTIONS START

  toggleGoogleRecaptchaFields() {
    if (this.requireCaptchaForEmailPasswordRegistrationTarget.checked) {
      recaptchaFields.classList.remove('hidden');
    } else {
      recaptchaFields.classList.add('hidden');
    }
  }

  enableOrEditEmailAuthSettings(event) {
    event.preventDefault();
    if (this.emailAuthSettingsBtnTarget.dataset.buttonText === 'enable') {
      emailRegistrationCheckbox.checked = true;
      this.emailAuthSettingsBtnTarget.setAttribute('data-button-text', 'edit');
      this.enabledIndicatorTarget.classList.add('visible');
    }
    this.emailAuthSettingsBtnTarget.classList.add('hidden');
    emailAuthSettingsSection.classList.remove('hidden');
  }

  hideEmailAuthSettings(event) {
    event.preventDefault();
    this.emailAuthSettingsBtnTarget.classList.remove('hidden');
    emailAuthSettingsSection.classList.add('hidden');
  }

  activateEmailAuthModal(event) {
    event.preventDefault();
    this.configModalAnchorTarget.innerHTML = adminModal({
      title: emailAuthModalTitle,
      controllerName: 'config',
      closeModalFunction: 'closeAdminModal',
      body: emailAuthModalBody,
      leftBtnText: 'Confirm disable',
      leftBtnAction: 'disableEmailAuthFromModal',
      rightBtnText: 'Cancel',
      rightBtnAction: 'closeAdminModal',
      leftBtnClasses: 'crayons-btn--danger',
      rightBtnClasses: 'crayons-btn--secondary',
    });
    this.positionModalOnPage();
  }

  disableEmailAuthFromModal(event) {
    event.preventDefault();
    this.disableEmailAuth(event);
    this.closeAdminModal();
  }

  disableEmailAuth(event) {
    event.preventDefault();
    emailRegistrationCheckbox.checked = false;
    this.emailAuthSettingsBtnTarget.innerHTML = 'Enable';
    this.emailAuthSettingsBtnTarget.setAttribute('data-button-text', 'enable');
    this.enabledIndicatorTarget.classList.remove('visible');
    this.hideEmailAuthSettings(event);
  }

  // EMAIL AUTH FUNCTIONS END

  // AUTH PROVIDERS FUNCTIONS START

  enableOrEditAuthProvider(event) {
    event.preventDefault();
    const { providerName } = event.target.dataset;
    const enabledIndicator = document.getElementById(
      `${providerName}-enabled-indicator`,
    );

    document
      .getElementById(`${providerName}-auth-settings`)
      .classList.remove('hidden');
    event.target.classList.add('hidden');

    if (event.target.dataset.buttonText === 'enable') {
      enabledIndicator.classList.add('visible');
      event.target.setAttribute('data-enable-auth', 'true');
      this.listAuthToBeEnabled();
    }
  }

  disableAuthProvider(event) {
    event.preventDefault();
    const { providerName } = event.target.dataset;
    const enabledIndicator = document.getElementById(
      `${providerName}-enabled-indicator`,
    );
    const authEnableButton = document.getElementById(
      `${providerName}-auth-btn`,
    );
    authEnableButton.setAttribute('data-enable-auth', 'false');
    enabledIndicator.classList.remove('visible');
    this.listAuthToBeEnabled();
    this.hideAuthProviderSettings(event);
  }

  authProviderModalTitle(provider) {
    return `Disable ${provider} login`;
  }

  authProviderModalBody(provider) {
    return `<p>If you disable ${provider} as a login option, people cannot authenticate with ${provider}.</p><p><strong>You must update Settings to save this action!</strong></p>`;
  }

  activateAuthProviderModal(event) {
    event.preventDefault();
    const { providerName } = event.target.dataset;
    const { providerOfficialName } = event.target.dataset;
    this.configModalAnchorTarget.innerHTML = adminModal({
      title: this.authProviderModalTitle(providerOfficialName),
      controllerName: 'config',
      closeModalFunction: 'closeAdminModal',
      body: this.authProviderModalBody(providerOfficialName),
      leftBtnText: 'Confirm disable',
      leftBtnAction: 'disableAuthProviderFromModal',
      rightBtnText: 'Cancel',
      rightBtnAction: 'closeAdminModal',
      leftBtnClasses: 'crayons-btn--danger',
      rightBtnClasses: 'crayons-btn--secondary',
      leftCustomDataAttr: `data-provider-name=${providerName}`,
    });
    this.positionModalOnPage();
  }

  disableAuthProviderFromModal(event) {
    event.preventDefault();
    const { providerName } = event.target.dataset;
    const authEnableButton = document.getElementById(
      `${providerName}-auth-btn`,
    );
    const enabledIndicator = document.getElementById(
      `${providerName}-enabled-indicator`,
    );
    authEnableButton.setAttribute('data-enable-auth', 'false');
    this.listAuthToBeEnabled(event);
    this.checkForAndGuardSoleAuthProvider();
    enabledIndicator.classList.remove('visible');
    this.hideAuthProviderSettings(event);
    this.closeAdminModal();
  }

  checkForAndGuardSoleAuthProvider() {
    if (
      document.querySelectorAll('[data-enable-auth="true"]').length === 1 &&
      document
        .getElementById('email-auth-enable-edit-btn')
        .getAttribute('data-button-text') === 'enable'
    ) {
      const targetAuthDisableBtn = document.querySelector(
        '[data-enable-auth="true"]',
      );
      targetAuthDisableBtn.parentElement.classList.add('crayons-hover-tooltip');
      targetAuthDisableBtn.parentElement.setAttribute(
        'data-tooltip',
        'To edit this, you must first enable Email address as a registration option',
      );
      targetAuthDisableBtn.setAttribute('disabled', true);
    }
  }

  hideAuthProviderSettings(event) {
    event.preventDefault();
    const { providerName } = event.target.dataset;
    document
      .getElementById(`${providerName}-auth-settings`)
      .classList.add('hidden');
    document
      .getElementById(`${providerName}-auth-btn`)
      .classList.remove('hidden');
  }

  listAuthToBeEnabled() {
    const enabledProviderArray = [];
    document
      .querySelectorAll('[data-enable-auth="true"]')
      .forEach((provider) => {
        enabledProviderArray.push(provider.dataset.providerName);
      });
    document.getElementById('auth_providers_to_enable').value =
      enabledProviderArray;
  }

  adjustAuthenticationOptions() {
    if (this.inviteOnlyModeTarget.checked) {
      document.getElementById('auth_providers_to_enable').value = '';
      emailRegistrationCheckbox.checked = false;
    } else {
      emailRegistrationCheckbox.checked = true;
    }
  }
  // AUTH PROVIDERS FUNCTIONS END

  enabledProvidersWithMissingKeys() {
    const providersWithMissingKeys = [];
    document
      .querySelectorAll('[data-enable-auth="true"]')
      .forEach((provider) => {
        const { providerName } = provider.dataset;
        if (providerName == 'apple') {
          if (
            !document.getElementById('settings_authentication_apple_client_id')
              .value ||
            !document.getElementById('settings_authentication_apple_key_id')
              .value ||
            !document.getElementById('settings_authentication_apple_pem')
              .value ||
            !document.getElementById('settings_authentication_apple_team_id')
              .value
          ) {
            providersWithMissingKeys.push(providerName);
          }
        } else if (
          !document.getElementById(
            `settings_authentication_${providerName}_key`,
          ).value ||
          !document.getElementById(
            `settings_authentication_${providerName}_secret`,
          ).value
        ) {
          providersWithMissingKeys.push(providerName);
        }
      });

    return providersWithMissingKeys;
  }

  generateProvidersList(providers) {
    const list = providers.reduce((html, provider) => {
      return `${html}<li class="capitalize">${provider}</li>`;
    }, '');

    return list;
  }

  missingAuthKeysModalBody(providers) {
    return `
      <p>You haven't filled out all of the required fields to enable the following authentication providers:</p>
      <ul class="mb-0">${this.generateProvidersList(providers)}</ul>
      <p class="mb-0">You may continue editing these authentication providers, or you may cancel.</p>
    `;
  }

  submitForm() {
    this.authSectionFormTarget.submit();
  }

  activateMissingKeysModal(providers) {
    this.configModalAnchorTarget.innerHTML = adminModal({
      title: 'Setup not complete',
      controllerName: 'config',
      closeModalFunction: 'closeAdminModal',
      body: this.missingAuthKeysModalBody(providers),
      leftBtnText: 'Continue editing',
      leftBtnAction: 'closeAdminModal',
      rightBtnText: 'Cancel',
      rightBtnAction: 'cancelAuthProviderEnable',
      rightBtnClasses: 'crayons-btn--secondary',
    });
  }

  configUpdatePrecheck(event) {
    if (this.enabledProvidersWithMissingKeys().length > 0) {
      event.preventDefault();
      this.activateMissingKeysModal(this.enabledProvidersWithMissingKeys());
    } else {
      this.updateConfigurationSettings(event);
    }
  }

  cancelAuthProviderEnable() {
    const providers = this.enabledProvidersWithMissingKeys();

    providers.forEach((provider) => {
      const enabledIndicator = document.getElementById(
        `${provider}-enabled-indicator`,
      );
      const authEnableButton = document.getElementById(`${provider}-auth-btn`);

      authEnableButton.setAttribute('data-enable-auth', 'false');
      enabledIndicator.classList.remove('visible');
      this.listAuthToBeEnabled();
      document
        .getElementById(`${provider}-auth-settings`)
        .classList.add('hidden');
      document
        .getElementById(`${provider}-auth-btn`)
        .classList.remove('hidden');

      this.closeAdminModal();
    });
  }
}
