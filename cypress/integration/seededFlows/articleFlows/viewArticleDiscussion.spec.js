describe('View article discussion', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug/comments');
    });
  });

  it('follows and unfollows a user from a comment preview card', () => {
    // Make sure the page has loaded
    cy.findByRole('link', { name: 'Read full post' });

    // Make sure the preview card is ready to be interacted with
    cy.get('[data-initialized]');
    cy.findByRole('button', { name: 'Admin McAdmin profile details' }).click();

    cy.findByTestId('profile-preview-card').within(() => {
      cy.findByRole('button', { name: 'Follow' }).as('userFollowButton');
      cy.get('@userFollowButton').click();

      // Confirm the follow button has been updated
      cy.get('@userFollowButton').should('have.text', 'Following');

      // Repeat and check the button changes back to 'Follow'
      cy.get('@userFollowButton').click();
      cy.get('@userFollowButton').should('have.text', 'Follow');
    });
  });
});
