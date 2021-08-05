describe('Follow user from profile page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/bachmanity');
      cy.get('[data-follow-clicks-initialized]');
    });
  });

  it('follows and unfollows an organisation', () => {
    cy.intercept('/follows').as('followsRequest');

    cy.findByRole('button', { name: 'Follow' }).click();
    cy.wait('@followsRequest');
    cy.findByRole('button', { name: 'Following' });

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/bachmanity');

    cy.findByRole('button', { name: 'Following' }).click();
    cy.wait('@followsRequest');

    cy.findByRole('button', { name: 'Follow' });

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/bachmanity');
    cy.findByRole('button', { name: 'Follow' });
  });
});
