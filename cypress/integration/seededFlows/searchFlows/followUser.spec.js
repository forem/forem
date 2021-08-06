describe('Follow user from search results', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  it('Shows an edit profile button for the current user', () => {
    cy.visitAndWaitForUserSideEffects(
      '/search?q=admin&filters=class_name:User',
    );

    cy.findByRole('button', { name: 'Edit profile' }).click();
    cy.findByRole('heading', { name: 'Settings for @admin_mcadmin' });
  });

  it('Follows and unfollows a user from search results', () => {
    cy.visitAndWaitForUserSideEffects(
      '/search?q=article&filters=class_name:User',
    );

    cy.intercept('/follows').as('followsRequest');

    cy.findAllByRole('button', { name: 'Follow' }).first().as('followButton');
    cy.get('@followButton').click();

    cy.wait('@followsRequest');
    cy.get('@followButton').should('have.text', 'Following');

    cy.get('@followButton').click();
    cy.wait('@followsRequest');
    cy.get('@followButton').should('have.text', 'Follow');
  });
});
