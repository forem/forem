describe('Lock discussion', () => {
  const getDiscussionLockButton = () =>
    cy.findByRole('link', {
      name: /Lock discussion/,
    });

  const getDiscussionUnlockButton = () =>
    cy.findByRole('link', {
      name: /Unlock discussion/,
    });

  const getDiscussionLockSubmitButton = () => cy.get('.crayons-btn--danger');

  describe('Unlocking the discussion', () => {
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
          }).then((response) => {
            cy.visit(`${response.body.current_state_path}/manage`);
            getDiscussionLockButton().click();
            getDiscussionLockSubmitButton().click();
          });
        });
      });
    });

    it('should allow a user to unlock a discussion', () => {
      getDiscussionUnlockButton().click();
      getDiscussionLockSubmitButton().click();

      cy.findByRole('heading', {
        name: 'Discussion was successfully unlocked!',
      }).should('exist');
    });

    it('should ask the user to confirm the discussion unlock', () => {
      getDiscussionUnlockButton().click();

      cy.findByRole('heading', {
        name: 'Are you sure you want to unlock the discussion on this article?',
      }).should('exist');

      cy.findByRole('button', {
        name: /Unlock discussion/,
      }).should('exist');
    });
  });
});
