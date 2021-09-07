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

    cy.findByRole('button', {
      name: 'Follow organization: Bachmanity',
    }).click();
    cy.wait('@followsRequest');
    cy.findByRole('button', { name: 'Unfollow organization: Bachmanity' });

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/bachmanity');

    cy.findByRole('button', {
      name: 'Unfollow organization: Bachmanity',
    }).click();
    cy.wait('@followsRequest');

    cy.findByRole('button', { name: 'Follow organization: Bachmanity' });

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/bachmanity');
    cy.findByRole('button', { name: 'Follow organization: Bachmanity' });
  });
});
