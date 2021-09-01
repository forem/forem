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
      name: 'Developer on Fire Developer on Fire Follow',
    });
    cy.findByRole('button', { name: 'Follow' }).as('followButton');

    cy.get('@followButton').click();
    // Inner text should now be following
    cy.get('@followButton').should('have.text', 'Following');

    // Check that state is persisted on refresh
    cy.visitAndWaitForUserSideEffects('/developeronfire');
    cy.findByRole('button', { name: 'Following' }).as('followButton');

    // Check it reverts back to Follow on click
    cy.get('@followButton').click();
    cy.get('@followButton').should('have.text', 'Follow');

    // Check that state is persisted on refresh
    cy.visitAndWaitForUserSideEffects('/developeronfire');
    cy.findByRole('button', { name: 'Follow' }).as('followButton');
  });
});
