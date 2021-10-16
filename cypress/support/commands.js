import { getInterceptsForLingeringUserRequests } from '../util/networkUtils';

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
 * Use this function to sign a user out without lingering network calls causing unintended side-effects.
 */
Cypress.Commands.add('signOutUser', () => {
  const intercepts = getInterceptsForLingeringUserRequests('/', false);

  return cy.request('DELETE', '/users/sign_out').then(() => {
    cy.visit('/');
    cy.wait(intercepts);
  });
});

/**
 * Logins in a user and visits the given URL, waiting for all user-related network requests triggered by the login to complete.
 * This ensures that no user side effects bleed into subsequent tests.
 */
Cypress.Commands.add('loginAndVisit', (user, url) => {
  cy.loginUser(user).then(() => {
    cy.visitAndWaitForUserSideEffects(url);
  });
});

/**
 * Visits the given URL, waiting for all user-related network requests to complete.
 * This ensures that no user side effects bleed into subsequent tests.
 */
Cypress.Commands.add('visitAndWaitForUserSideEffects', (url, options) => {
  // If navigating directly to an admin route, no relevant network requests to intercept
  const { baseUrl } = Cypress.config().baseUrl;
  if (url === `${baseUrl}/admin` || url.includes('/admin/')) {
    cy.visit(url, options);
  } else {
    const intercepts = getInterceptsForLingeringUserRequests(url, true);
    cy.visit(url, options);
    cy.wait(intercepts);
  }
});

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

  function getLoginRequest() {
    return cy.request(
      'POST',
      '/users/sign_in',
      `utf8=%E2%9C%93&user%5Bemail%5D=${encodedEmail}&user%5Bpassword%5D=${encodedPassword}&user%5Bremember_me%5D=0&user%5Bremember_me%5D=1&commit=Continue`,
    );
  }

  return getLoginRequest().then((response) => {
    if (response.status === 200) {
      return response;
    }

    cy.log('Login failed. Attempting one more login.');

    // If we have a login failure, try one more time.
    // This is to combat some flaky tests where the login fails occasionnally.
    return getLoginRequest();
  });
});

/**
 * Logs in a creator with the given name, username, email, and password.
 *
 * @param credentials
 * @param credentials.name {string} A name
 * @param credentials.username {string} A username
 * @param credentials.email {string} An email address
 * @param credentials.password {string} A password
 *
 * @returns {Cypress.Chainable<Cypress.Response>} A cypress request for signing in a creator.
 */
Cypress.Commands.add('loginCreator', ({ name, username, email, password }) => {
  const encodedName = encodeURIComponent(name);
  const encodedUsername = encodeURIComponent(username);
  const encodedEmail = encodeURIComponent(email);
  const encodedPassword = encodeURIComponent(password);

  function getLoginRequest() {
    return cy.request(
      'POST',
      '/users',
      `utf8=%E2%9C%93&user%5Bname%5D=${encodedName}&user%5Busername%5D=${encodedUsername}&user%5Bemail%5D=${encodedEmail}%40forem.local&user%5Bpassword%5D=${encodedPassword}&commit=Create+my+account`,
    );
  }

  return getLoginRequest().then((response) => {
    if (response.status === 200) {
      return response;
    }

    cy.log('Login failed. Attempting one more login.');

    // If we have a login failure, try one more time.
    // This is to combat some flaky tests where the login fails occasionnally.
    return getLoginRequest();
  });
});

/**
 * Gets an iframe with the given selector (or the first/only iframe if none is passed in),
 * waits for its content to be loaded, and returns a wrapped reference to the iframe body
 * that can then be chained off of.
 *
 * See also: https://www.cypress.io/blog/2020/02/12/working-with-iframes-in-cypress/
 *
 * @example
 * cy.getIframeBody('.article-frame').findByRole('heading', { name: 'Article title' });
 */
Cypress.Commands.add('getIframeBody', (selector = '') =>
  cy
    .get(`iframe${selector}`)
    .its('0.contentDocument.body')
    .should('not.be.empty')
    .then(cy.wrap),
);

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
 * Sets default values of Settings::General atrributes relevant to Authentication Section.
 *
 * @param username {string} The username used in the test
 * @param settingsGeneral
 * @param settingsGeneral.inviteOnlyMode {boolean}
 * @param settingsGeneral.emailRegistration {boolean}
 * @param settingsGeneral.allowedEmailDomains {string}
 * @param settingsGeneral.publicEmailDomainList {boolean}
 * @param settingsGeneral.requireRecaptcha {boolean}
 * @param settingsGeneral.recaptchaSiteKey {string}
 * @param settingsGeneral.recaptchaSecretKey {string}
 * @param settingsGeneral.authProvidersToEnable {string} Comma-separated string of providers to be enabled
 * @param settingsGeneral.facebookKey {string}
 * @param settingsGeneral.facebookSecret {string}
 * @param settingsGeneral.githubKey {string}
 * @param settingsGeneral.githubSecret {string}
 * @param settingsGeneral.twitterKey {string}
 * @param settingsGeneral.twitterSecret {string}
 *
 * @returns {Cypress.Chainable<Cypress.Response>} A cypress request for setting Settings::General values for the Authentication Section.
 */
Cypress.Commands.add(
  'updateAdminAuthConfig',
  ({
    inviteOnlyMode = false,
    emailRegistration = true,
    allowedEmailDomains = '',
    publicEmailDomainList = false,
    requireRecaptcha = false,
    recaptchaSiteKey = '',
    recaptchaSecretKey = '',
    authProvidersToEnable,
    facebookKey = '',
    facebookSecret = '',
    githubKey = '',
    githubSecret = '',
    twitterKey = '',
    twitterSecret = '',
  } = DEFAULT_AUTH_CONFIG) => {
    return cy.request(
      'POST',
      '/admin/settings/authentications',
      `utf8=%E2%9C%93&settings_authentication%5Binvite_only_mode%5D=${toPayload(
        inviteOnlyMode,
      )}&settings_authentication%5Ballow_email_password_registration%5D=${toPayload(
        emailRegistration,
      )}&settings_authentication%5Ballowed_registration_email_domains%5D=${allowedEmailDomains}&settings_authentication%5Bdisplay_email_domain_allow_list_publicly%5D=${toPayload(
        publicEmailDomainList,
      )}&settings_authentication%5Brequire_captcha_for_email_password_registration%5D=${toPayload(
        requireRecaptcha,
      )}&settings_authentication%5Brecaptcha_site_key%5D=${recaptchaSiteKey}&settings_authentication%5Brecaptcha_secret_key%5D=${recaptchaSecretKey}&settings_authentication%5Bauth_providers_to_enable%5D=${authProvidersToEnable}&settings_authentication%5Bfacebook_key%5D=${facebookKey}&settings_authentication%5Bfacebook_secret%5D=${facebookSecret}&settings_authentication%5Bgithub_key%5D=${githubKey}&settings_authentication%5Bgithub_secret%5D=${githubSecret}&settings_authentication%5Btwitter_key%5D=${twitterKey}&settings_authentication%5Btwitter_secret%5D=${twitterSecret}&commit=Update+Settings`,
    );
  },
);

/**
 * Creates an article.
 *
 * @param {string} title The title of an article.
 * @param {Array<string>} [tags=[]] The tags of an article.
 * @param {string} [content=''] The content of the article.
 * @param {boolean} [published=true] Whether or not an article should be published.
 * @param {string} [description=''] The description of the article.
 * @param {string} [canonicalUrl=''] The canonical URL for the article.
 * @param {string} [series=''] The series the article is associated with.
 * @param {string} [allSeries=[]] The list of available series the article can be a part of.
 * @param {string} [organizations=[]] The list of organizations the author of the article belongs to.
 * @param {string} [organizationId=null] The selected organization's ID to create the article under.
 * @param {'v1'|'v2'} [editorVersion='v2'] The editor version.
 *
 * @returns {Cypress.Chainable<Cypress.Response>} A cypress request for creating an article.
 */
Cypress.Commands.add(
  'createArticle',
  ({
    title,
    tags = [],
    content = '',
    published = true,
    description = '',
    canonicalUrl = '',
    mainImage = null,
    series = '',
    allSeries = [],
    organizations = [],
    organizationId = null,
    editorVersion = 'v2',
  }) => {
    return cy.request('POST', '/articles', {
      article: {
        id: null,
        title,
        tagList: tags.join(','),
        description,
        canonicalUrl,
        series,
        allSeries,
        bodyMarkdown: content,
        published,
        submitting: false,
        editing: false,
        mainImage,
        organizations,
        organizationId,
        edited: true,
        updatedAt: null,
        version: editorVersion,
      },
    });
  },
);

/**
 * Creates a response template.
 *
 * @param {string} title The title of a response template.
 * @param {string} content The content of the response template.
 *
 * @returns {Cypress.Chainable<Cypress.Response>} A cypress request for creating a response template.
 */
Cypress.Commands.add('createResponseTemplate', ({ title, content }) => {
  const encodedTitle = encodeURIComponent(title);
  const encodedContent = encodeURIComponent(content);

  return cy.request(
    'POST',
    '/response_templates',
    `utf8=%E2%9C%93&response_template%5Btitle%5D=${encodedTitle}&response_template%5Bcontent%5D=${encodedContent}`,
  );
});
