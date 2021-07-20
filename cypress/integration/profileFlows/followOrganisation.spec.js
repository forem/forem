describe('Follow user from profile page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/bachmanity');
    });
  });

  it('follows and unfollows an organisation', () => {
    cy.intercept('/follows').as('followsRequest');
    // Wait for the button to be initialised
    cy.get('[data-button-initialized="true"]');

    cy.findByRole('button', { name: 'Follow' }).click();
    cy.wait('@followsRequest');
    cy.findByRole('button', { name: 'Following' });

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/bachmanity');

    cy.get('[data-button-initialized="true"]');
    cy.findByRole('button', { name: 'Following' }).click();
    cy.wait('@followsRequest');

    cy.findByRole('button', { name: 'Follow' });

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/bachmanity');
    cy.get('[data-button-initialized="true"]');
    cy.findByRole('button', { name: 'Follow' });
  });
});
