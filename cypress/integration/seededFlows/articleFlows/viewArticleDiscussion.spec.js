describe('View article discussion', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug/comments');
      // Make sure the page has loaded
      cy.findByRole('heading', { name: 'Test article' });
    });
  });

  it('follows and unfollows a user from a comment preview card', () => {
    // Make sure the preview card is ready to be interacted with
    cy.get('[data-initialized]');
    cy.findByRole('button', { name: 'Admin McAdmin profile details' }).click();

    cy.findByTestId('profile-preview-card').within(() => {
      cy.findByRole('button', { name: 'Follow user: Admin McAdmin' }).as(
        'userFollowButton',
      );
      cy.get('@userFollowButton').click();

      // Confirm the follow button has been updated
      cy.get('@userFollowButton').should('have.text', 'Following');

      // Repeat and check the button changes back to 'Follow'
      cy.get('@userFollowButton').click();
      cy.get('@userFollowButton').should('have.text', 'Follow');
    });
  });

  it('initializes the follow button when a new comment is added', () => {
    cy.findByRole('textbox', { name: 'Add a comment to the discussion' }).type(
      'New comment',
    );
    cy.findByRole('button', { name: 'Submit' }).click();

    cy.findByRole('button', {
      name: 'Article Editor v1 User profile details',
    }).as('previewButton');

    // Make sure the newly added button is ready for interaction
    cy.get('@previewButton').should('have.attr', 'data-initialized');
    cy.get('@previewButton').click();

    cy.findAllByTestId('profile-preview-card')
      .first()
      .findByRole('button', { name: 'Edit profile' });
  });
});
