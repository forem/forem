import { getInterceptsForLingeringUserRequests } from '../../../util/networkUtils';

describe('User Logout', () => {
  beforeEach(() => {
    cy.testSetup();

    cy.fixture('users/changePasswordUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
    });
  });

  it('should allow a user to logout', () => {
    // Click on the sign out button
    cy.findByText('Sign Out').click({ force: true });

    // We intercept user-related network requests triggered on logout, so we can await them and avoid issues with a subsequent login
    const logoutNetworkRequests = getInterceptsForLingeringUserRequests(false);

    // Sign out confirmation page is rendered
    cy.url().should('contains', '/signout_confirm');
    cy.findByRole('button', { name: 'Yes, sign out' }).click();

    cy.wait(logoutNetworkRequests);

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
