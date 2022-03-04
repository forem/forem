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

    cy.findByRole('button', { name: 'Follow user: article_editor_v1_user' }).as(
      'followButton',
    );
    cy.get('@followButton').click();

    cy.wait('@followsRequest');
    cy.get('@followButton').should('have.text', 'Following');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    cy.get('@followButton').click();
    cy.wait('@followsRequest');
    cy.get('@followButton').should('have.text', 'Follow');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');
  });
});
