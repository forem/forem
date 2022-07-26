describe('Post share options', () => {
  const shareAvailableStub = {
    onBeforeLoad: (win) => {
      Object.defineProperty(win.navigator, 'share', { value: true });
    },
  };

  let articlePath = '';

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          articlePath = response.body.current_state_path;
        });
      });
    });
  });

  it('should display "Share Post via..." when navigator.share is available', () => {
    cy.visitAndWaitForUserSideEffects(articlePath, shareAvailableStub);
    cy.findByRole('button', { name: /^Share post options$/i }).as(
      'dropdownButton',
    );
    cy.get('@dropdownButton').click();
    cy.findByRole('link', { name: /^Share Post via...$/i }).should('exist');
  });

  it('should not display "Share Post via..." when navigator.share is unavailable', () => {
    cy.visitAndWaitForUserSideEffects(articlePath);
    cy.findByRole('button', { name: /^Share post options$/i }).as(
      'dropdownButton',
    );
    cy.get('@dropdownButton').click();
    cy.findByRole('link', { name: /^Share Post via...$/i }).should('not.exist');
  });
});
