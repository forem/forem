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

Cypress.Commands.add('updateAdminConfig', () => {
  return cy.request(
    'POST',
    '/admin/config',
    'utf8=%E2%9C%93&authenticity_token=9bV5spK%2FwoI1KW6X%2FEMqip5fxACN8kP3ol7EXrmCTvfzTopH7WZr8vlzQP%2FWu1bjykLDrkVq4ojzvFIwAEHL4Q%3D%3D&site_config%5Binvite_only_mode%5D=0&site_config%5Ballow_email_password_registration%5D=0&site_config%5Ballow_email_password_registration%5D=1&site_config%5Ballowed_registration_email_domains%5D=&site_config%5Bdisplay_email_domain_allow_list_publicly%5D=0&site_config%5Brequire_captcha_for_email_password_registration%5D=0&site_config%5Brecaptcha_site_key%5D=&site_config%5Brecaptcha_secret_key%5D=&site_config%5Bauth_providers_to_enable%5D=facebook&site_config%5Bfacebook_key%5D=swed&site_config%5Bfacebook_secret%5D=wedf&site_config%5Bgithub_key%5D=&site_config%5Bgithub_secret%5D=&site_config%5Btwitter_key%5D=&site_config%5Btwitter_secret%5D=&confirmation=My+username+is+%40admin_mcadmin+and+this+action+is+100%25+safe+and+appropriate.&commit=Update+Site+Configuration',
  );
});
