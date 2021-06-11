describe('Unlock discussion', () => {
  const getDiscussionLockButton = () =>
    cy.findByRole('link', {
      name: 'Lock discussion',
    });

  const getDiscussionUnlockButton = () =>
    cy.findByRole('link', {
      name: 'Unlock discussion',
    });

  const getDiscussionLockSubmitButton = () =>
    cy.findByRole('button', {
      name: 'Lock discussion',
    });

  const getDiscussionUnlockSubmitButton = () =>
    cy.findByRole('button', {
      name: 'Unlock discussion',
    });

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
      getDiscussionUnlockSubmitButton().click();

      getDiscussionLockButton().should('exist');
    });

    it('should ask the user to confirm the discussion unlock', () => {
      getDiscussionUnlockButton().click();

      cy.findByRole('heading', {
        name: 'Are you sure you want to unlock the discussion on this post?',
      }).should('exist');

      getDiscussionUnlockSubmitButton().should('exist');
    });
  });

  describe('when an article has its discussion unlocked', () => {
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
            cy.visit(response.body.current_state_path);
          });
        });
      });
    });

    it('should show the new comment box', () => {
      cy.get('#new_comment').should('exist');
    });

    it('should not show a discussion lock', () => {
      cy.get('#dicussion-lock').should('not.exist');
    });
  });
});
