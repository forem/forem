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

  it('should propogate the /new?prefill parameter', () => {
    cy.fixture('users/changePasswordUser.json').as('user');

    // Go to home page
    cy.visit(
      '/new?prefill=---%0Atitle%3A%20A%20swarm%20in%20a%20box%0Apublished%3A%20true%0Atags%3A%20codepen%0A---%0A%0A%0A%0A%7B%25%20embed%20https%3A%2F%2Fcodepen.io%2Ftrajektorijus%2Fpen%2FBaJOVeE%20%25%7D',
    );

    cy.url().should('contains', '/new?prefill=');

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

    cy.url().should('contains', '/new?prefill=');

    cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

    cy.get('@articleForm')
      .findByLabelText('Post Title')
      .should('have.value', 'A swarm in a box');

    cy.get('@articleForm')
      .findByLabelText('Post Content')
      .should(
        'have.value',
        '{% embed https://codepen.io/trajektorijus/pen/BaJOVeE %}',
      );
  });
});
