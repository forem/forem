describe('Follow podcast', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/developeronfire');
    });
  });

  it('Follows and unfollows a podcast', () => {
    cy.get('[data-follow-clicks-initialized]');

    cy.findByRole('heading', {
      name: 'Developer on Fire Developer on Fire',
    });

    cy.findByRole('button', { name: 'Follow podcast: Developer on Fire' }).as(
      'followButton',
    );

    cy.get('@followButton').click();
    // Inner text should now be following
    cy.get('@followButton').should('have.text', 'Following');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    // Check that state is persisted on refresh
    cy.visitAndWaitForUserSideEffects('/developeronfire');
    cy.findByRole('button', { name: 'Follow podcast: Developer on Fire' }).as(
      'followButton',
    );
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    // Check it reverts back to Follow on click
    cy.get('@followButton').click();
    cy.get('@followButton').should('have.text', 'Follow');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');

    // Check that state is persisted on refresh
    cy.visitAndWaitForUserSideEffects('/developeronfire');
    cy.findByRole('button', { name: 'Follow podcast: Developer on Fire' }).as(
      'followButton',
    );
  });
});
