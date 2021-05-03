describe('User Logout', () => {
  beforeEach(() => {
    cy.testSetup();

    cy.fixture('users/changePasswordUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/');
      });
    });
  });

  it('should allow a user to logout', () => {
    // Click on the sign out button
    cy.findByText('Sign Out').click({ force: true });

    // Sign out confirmation page is rendered
    cy.url().should('contains', '/signout_confirm');
    cy.findByRole('button', { name: 'Yes, sign out' }).click();

    // User should be redirected to the homepage
    const { baseUrl } = Cypress.config();
    cy.url().should('equal', `${baseUrl}`);

    // Make sure the state has updated to logged out
    cy.findAllByRole('link', { name: 'Log in' });

    // User data should not exist on the document or in localStorage
    cy.document().should((doc) => {
      expect(doc.body.dataset).not.to.have.property('user');
      expect(localStorage.getItem('current_user')).to.be.null;
    });
  });
});
