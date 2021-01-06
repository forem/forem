// Notes
// Need to situation where the Auth Provider we are testing is NOT enabled to start with and does NOT have any keys
// Can I set this up via SiteConfig ahead of the test?

describe('Enable Auth Provider', () => {
  beforeEach(() => {
    cy.fixture('logins/initialAdmin.json').as('admin');

    cy.visit('http://localhost:3000/');

    cy.findAllByText('Log in').first().click();
    cy.url().should('contains', 'http://localhost:3000/enter');

    cy.findByTestId('login-form').as('loginForm');
    cy.get('@admin').then((admin) => {
      cy.get('@loginForm').findByText('Email').type(admin.email);
      cy.get('@loginForm').findByText('Password').type(admin.password);
    });
    cy.get('@loginForm').findByText('Continue').click();

    cy.visit('http://localhost:3000/admin/config');
  });

  it('should display modal warning if provider keys are missing and enable provider anyways', () => {
    cy.findAllByText('Authentication').first().click();
    cy.get('#facebook-auth-btn').click();
    cy.get('#authenticationBodyContainer #confirmation').type(
      'My username is @admin_mcadmin and this action is 100% safe and appropriate.',
    );
    cy.get('#authenticationBodyContainer')
      .contains('Update Site Configuration')
      .click();

    cy.contains('Setup not complete').should('be.visible');
    cy.get('.crayons-modal__box__body > ul > li')
      .contains('Facebook')
      .should('be.visible');

    cy.get('.crayons-modal__box__body').contains('Save anyway').click();

    cy.url().should('contains', 'http://localhost:3000/admin/config');
    cy.get('.alert')
      .contains('Site configuration was successfully updated')
      .should('be.visible');
  });

  it('should not display modal warning if provider keys present', () => {
    cy.findAllByText('Authentication').first().click();
    cy.get('#facebook-auth-btn').click();
    cy.get('#site_config_facebook_key').type('randomkey');
    cy.get('#site_config_facebook_secret').type('randomsecret');
    cy.get('#authenticationBodyContainer #confirmation').type(
      'My username is @admin_mcadmin and this action is 100% safe and appropriate.',
    );
    cy.get('#authenticationBodyContainer')
      .contains('Update Site Configuration')
      .click();

    cy.url().should('contains', 'http://localhost:3000/admin/config');
    cy.get('.alert')
      .contains('Site configuration was successfully updated')
      .should('be.visible');
    cy.contains('Setup not complete').should('not.exist');
  });
});
