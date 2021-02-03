// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add("login", (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

/**
 * Runs necessary test setup to run a clean test.
 */
Cypress.Commands.add('testSetup', () => {
  // Required for the moment because of https://github.com/cypress-io/cypress/issues/781
  cy.clearCookies();

  cy.getCookies().then((cookie) => {
    if (cookie.length) {
      // Instead of always waiting, only wait if the cookies aren't
      // cleared yet and attempt to clear again.
      cy.wait(500); // eslint-disable-line cypress/no-unnecessary-waiting
      cy.clearCookies();
    }
  });

  cy.request('/cypress_rails_reset_state');
});

/**
 * Logs in a user with the given email and password.
 *
 * @param credentials
 * @param credentials.email {string} An email address
 * @param credentials.password {string} A password
 *
 * @returns {Cypress.Chainable<Cypress.Response>} A cypress request for signing in a user.
 */
Cypress.Commands.add('loginUser', ({ email, password }) => {
  const encodedEmail = encodeURIComponent(email);
  const encodedPassword = encodeURIComponent(password);

  return cy.request(
    'POST',
    '/users/sign_in',
    `utf8=%E2%9C%93&user%5Bemail%5D=${encodedEmail}&user%5Bpassword%5D=${encodedPassword}&user%5Bremember_me%5D=0&user%5Bremember_me%5D=1&commit=Continue`,
  );
});

const toPayload = (isEnabled) => (isEnabled ? '1' : '0');

const DEFAULT_AUTH_CONFIG = {
  inviteOnlyMode: false,
  emailRegistration: true,
  allowedEmailDomains: '',
  publicEmailDomainList: false,
  requireRecaptcha: false,
  recaptchaSiteKey: '',
  recaptchaSecretKey: '',
  authProvidersToEnable: '',
  facebookKey: '',
  facebookSecret: '',
  githubKey: '',
  githubSecret: '',
  twitterKey: '',
  twitterSecret: '',
};

/**
 * Sets default values of SiteConfig atrributes relevant to Authentication Section.
 *
 * @param username {string} The username used in the test
 * @param siteConfig
 * @param siteConfig.inviteOnlyMode {boolean}
 * @param siteConfig.emailRegistration {boolean}
 * @param siteConfig.allowedEmailDomains {string}
 * @param siteConfig.publicEmailDomainList {boolean}
 * @param siteConfig.requireRecaptcha {boolean}
 * @param siteConfig.recaptchaSiteKey {string}
 * @param siteConfig.recaptchaSecretKey {string}
 * @param siteConfig.authProvidersToEnable {string} Comma-separated string of providers to be enabled
 * @param siteConfig.facebookKey {string}
 * @param siteConfig.facebookSecret {string}
 * @param siteConfig.githubKey {string}
 * @param siteConfig.githubSecret {string}
 * @param siteConfig.twitterKey {string}
 * @param siteConfig.twitterSecret {string}
 *
 * @returns {Cypress.Chainable<Cypress.Response>} A cypress request for setting SiteConfig values for the Authentication Section.
 */
Cypress.Commands.add(
  'updateAdminAuthConfig',
  (
    username = 'admin_mcadmin',
    {
      inviteOnlyMode = false,
      emailRegistration = true,
      allowedEmailDomains,
      publicEmailDomainList = false,
      requireRecaptcha = false,
      recaptchaSiteKey,
      recaptchaSecretKey,
      authProvidersToEnable,
      facebookKey,
      facebookSecret,
      githubKey,
      githubSecret,
      twitterKey,
      twitterSecret,
    } = DEFAULT_AUTH_CONFIG,
  ) => {
    return cy.request(
      'POST',
      '/admin/config',
      `utf8=%E2%9C%93&site_config%5Binvite_only_mode%5D=${toPayload(
        inviteOnlyMode,
      )}&site_config%5Ballow_email_password_registration%5D=${toPayload(
        emailRegistration,
      )}&site_config%5Ballowed_registration_email_domains%5D=${allowedEmailDomains}&site_config%5Bdisplay_email_domain_allow_list_publicly%5D=${toPayload(
        publicEmailDomainList,
      )}&site_config%5Brequire_captcha_for_email_password_registration%5D=${toPayload(
        requireRecaptcha,
      )}&site_config%5Brecaptcha_site_key%5D=${recaptchaSiteKey}&site_config%5Brecaptcha_secret_key%5D=${recaptchaSecretKey}&site_config%5Bauth_providers_to_enable%5D=${authProvidersToEnable}&site_config%5Bfacebook_key%5D=${facebookKey}&site_config%5Bfacebook_secret%5D=${facebookSecret}&site_config%5Bgithub_key%5D=${githubKey}&site_config%5Bgithub_secret%5D=${githubSecret}&site_config%5Btwitter_key%5D=${twitterKey}&site_config%5Btwitter_secret%5D=${twitterSecret}&confirmation=My+username+is+%40${username}+and+this+action+is+100%25+safe+and+appropriate.&commit=Update+Site+Configuration`,
    );
  },
);
