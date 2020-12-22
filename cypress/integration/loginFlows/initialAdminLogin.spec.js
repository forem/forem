// Note if you are running these tests locallly, this test will fail
// if the first admin has already gone through the onboarding process.

describe('Initial admin signup', () => {
  it('should sign up the initial Forem instance administrator', () => {
    // This is the happy path.
    cy.fixture('logins/initialAdmin.json').as('admin');

    cy.log('baseUrl', Cypress.config().baseUrl);

    // Go to home page which redirects to the registration form.
    cy.visit('/');

    cy.findByTestId('registration-form').as('registrationForm');

    cy.get('@registrationForm')
      .findByLabelText(/Profile image/i)
      .attachFile('images/admin-image.png');

    cy.get('@admin').then((admin) => {
      // Enter credentials for the initial administrator user
      cy.get('@registrationForm')
        .findByLabelText(/^Name$/i)
        .type(admin.name);
      cy.get('@registrationForm')
        .findByLabelText(/Username/i)
        .type(admin.username);
      cy.get('@registrationForm')
        .findByLabelText(/^Email$/i)
        .type(admin.email);
      cy.get('@registrationForm')
        .findByLabelText('Password')
        .type(admin.password);
      cy.get('@registrationForm')
        .findByLabelText(/^Password Confirmation$/i)
        .type(admin.password);
      cy.get('@registrationForm')
        .findByLabelText(/New Forem Secret/i)
        .type(admin.foremSecret);

      // Submit the form
      cy.get('@registrationForm')
        .findByText(/^Sign up$/)
        .click();
      cy.log('Submitting signup form');

      // The initial administrator user was create and is redirected to the confirm email screen.
      cy.url().should(
        'eq',
        Cypress.config().baseUrl + '/confirm-email?email=' + admin.email,
      );

      cy.findByTestId('resend-confirmation-form').as('confirmationForm');
      cy.get('@confirmationForm')
        .findByLabelText(/^Confirmation email address$/i)
        .should('have.value', admin.email);
      cy.get('@confirmationForm').findByText(
        /^Resend confirmation instructions$/i,
      );
    });
  });
});
