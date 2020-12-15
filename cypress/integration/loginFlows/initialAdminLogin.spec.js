describe('Initial admin signup', () => {
  // Note if you are running these tests locallly, this test will fail
  // if the first admin has already gone through the onboarding process.
  it('should sign up the initial Forem instance administrator', () => {
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
      cy.get('@registrationForm').findByLabelText(/Email/i).type(admin.email);
      cy.get('@registrationForm')
        .findByLabelText('Password')
        .type(admin.password);
      cy.get('@registrationForm')
        .findByLabelText(/Password Confirmation/i)
        .type(admin.password);
      cy.get('@registrationForm')
        .findByLabelText(/New Forem Secret/i)
        .type(admin.foremSecret);
    });

    // Submit the form
    cy.get('@registrationForm').findByText('Sign up').click();
    cy.log('Submitting signup form');
    cy.url().should('eq', Cypress.config().baseUrl + '/users');

    cy.findByTestId('signup-errors').should('not.exist');
  });
});
