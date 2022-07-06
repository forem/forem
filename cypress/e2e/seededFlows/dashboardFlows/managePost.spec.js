describe('Manage Post', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then(() => {
          cy.visitAndWaitForUserSideEffects('/dashboard');
        });
      });
    });
  });

  it('allows a user to archive a post', () => {
    cy.findByRole('link', { name: 'Manage post: Test Article' }).click();

    // Make sure we're on the manage post page
    cy.findByRole('heading', { name: 'Test Article' });

    // Make sure the button is ready
    cy.get('button[id^=ellipsis-menu-trigger-][data-initialized]');
    cy.findByRole('button', { name: 'More...' }).click();

    cy.findByRole('button', { name: 'Archive post' })
      .should('have.focus')
      .click();

    // Currently archiving from this view removes the "more..." options and there's no visual confirmation of the archive status
    cy.findByRole('button', { name: 'More...' }).should('not.exist');
  });
});
