describe('User Login', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should login a user', () => {
    cy.fixture('users/changePasswordUser.json').as('user');

    // Go to home page
    cy.visit('/');

    // Click on the login button in the top header
    cy.findAllByText('Log in').first().click();

    // Ensure we are redirected to the login page
    cy.url().should('contains', '/enter');

    cy.findByTestId('login-form').as('loginForm');

    cy.get('@user').then((user) => {
      cy.get('@loginForm')
        .findByText(/^Email$/)
        .type(user.email);
      cy.get('@loginForm')
        .findByText(/^Password$/)
        .type(user.password);
    });

    // Submit the form
    cy.get('@loginForm').findByText('Continue').click();

    // User should be redirected to onboarding
    const { baseUrl } = Cypress.config();
    cy.url().should('equal', `${baseUrl}?signin=true`);
  });
});
