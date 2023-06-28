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

    cy.get('#user-follow-butt').as('followButton');
    cy.get('@followButton').click();
    cy.wait('@followsRequest');

    cy.get('@followButton').should('have.text', 'Following');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/article_editor_v1_user');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    cy.get('@followButton').click();

    cy.wait('@followsRequest');

    cy.get('@followButton').should('have.text', 'Follow');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');

    // Check that the update persists after reload
    cy.reload();
    cy.get('@followButton').should('have.text', 'Follow');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');
  });
});
