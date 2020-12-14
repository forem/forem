describe('First time for first administrator login', () => {
  // Note if you are running these tests locallly, this test will fail
  // if the first admin has already gone through the onboarding process.
  it('should login the initial administrator user from the home page', () => {
    cy.fixture('logins/initialAdmin.json').as('admin');

    // Go to home page
    cy.visit('/');

    // Click on the login button in the top header
    cy.findAllByText('Log in').first().click();

    // Ensure we are redirected to the login page
    cy.url().should('contains', '/enter');

    cy.findByTestId('login-form').as('loginForm');
    cy.get('@admin').then((admin) => {
      // Enter credentials for the initial administrator user
      cy.get('@loginForm').findByText('Email').type(admin.user);
      cy.get('@loginForm').findByText('Password').type(admin.password);
    });

    // Submit the form
    cy.get('@loginForm').findByText('Continue').click();

    // User should be redirected to onboarding
    const { baseUrl } = Cypress.config();
    cy.url().should('include', `/onboarding?referrer=${baseUrl}/?signin=true`);
  });
});
