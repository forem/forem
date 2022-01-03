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

    cy.findByRole('button', { name: 'Follow organization: Bachmanity' }).as(
      'followButton',
    );

    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');

    cy.get('@followButton').click();
    // Inner text should now be following
    cy.get('@followButton').should('have.text', 'Following');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    // Check that state is persisted on refresh
    cy.visitAndWaitForUserSideEffects('/bachmanity');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    // Check it reverts back to Follow on click
    cy.get('@followButton').click();
    cy.get('@followButton').should('have.text', 'Follow');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');

    // Check that the update persists after reload
    cy.visitAndWaitForUserSideEffects('/bachmanity');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');
  });
});
