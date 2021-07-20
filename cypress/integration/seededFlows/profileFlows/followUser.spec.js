describe('Follow user from profile page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/article_editor_v1_user');
    });
  });

  it('follows and unfollows a user', () => {
    // Wait for the button to be initialised
    cy.get('[data-click-initialized="true"]');

    cy.findByRole('button', { name: 'Follow' }).click();
    cy.findByRole('button', { name: 'Following' });

    // Check that the update persists after reload
    cy.reload();
    cy.get('[data-click-initialized="true"]');
    cy.findByRole('button', { name: 'Following' }).click();
    cy.findByRole('button', { name: 'Follow' });

    // Check that the update persists after reload
    cy.reload();
    cy.get('[data-click-initialized="true"]');
    cy.findByRole('button', { name: 'Follow' });
  });
});
