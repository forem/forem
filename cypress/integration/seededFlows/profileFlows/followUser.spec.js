describe('Follow user from profile page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/article_editor_v1_user');
      cy.get('[data-follow-clicks-initialized]');
    });
  });

  it('follows and unfollows a user', () => {
    cy.intercept('/follows').as('followsRequest');

    cy.findByRole('button', {
      name: 'Follow user: Article Editor v1 User',
    }).click();
    cy.wait('@followsRequest');
    cy.findByRole('button', { name: 'Unfollow user: Article Editor v1 User' });

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/article_editor_v1_user');

    cy.findByRole('button', {
      name: 'Unfollow user: Article Editor v1 User',
    }).click();
    cy.wait('@followsRequest');

    cy.findByRole('button', { name: 'Follow user: Article Editor v1 User' });

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/article_editor_v1_user');
    cy.findByRole('button', { name: 'Follow user: Article Editor v1 User' });
  });
});
