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

  const exampleReason = 'Discussion lock example reason!';
  const exampleNotes = 'Discussion lock example notes!';

  describe('locking the discussion', () => {
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
          });
        });
      });
    });

    it('should allow a user to lock a discussion', () => {
      getDiscussionLockButton().click();
      getDiscussionLockSubmitButton().click();

      getDiscussionUnlockButton().should('exist');
    });

    it('should ask the user to confirm the discussion lock', () => {
      getDiscussionLockButton().click();

      cy.findByRole('heading', {
        name: 'Are you sure you want to lock the discussion on this article?',
      }).should('exist');

      cy.findByRole('button', {
        name: /Lock discussion/,
      }).should('exist');
    });

    it('should allow a user to supply a reason and notes', () => {
      getDiscussionLockButton().click();
      cy.get('input[name="discussion_lock[notes]"]').should('exist');
      cy.get('input[name="discussion_lock[reason]"]').should('exist');
    });
  });

  describe('when an article has its discussion locked', () => {
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
            const articlePath = response.body.current_state_path;
            cy.visit(`${articlePath}/manage`);
            getDiscussionLockButton().click();
            cy.get('#discussion_lock_reason')
              .should('be.visible')
              .type(exampleReason);
            cy.get('#discussion_lock_notes')
              .should('be.visible')
              .type(exampleNotes);
            getDiscussionLockSubmitButton().click();
            cy.visit(articlePath);
          });
        });
      });
    });

    it('should show the discussion lock on an article', () => {
      cy.get('#discussion-lock').should('exist');
    });

    it('should show the discussion lock reason on an article', () => {
      cy.get('#discussion-lock').should(($discussionLock) => {
        expect($discussionLock).to.contain.text(exampleReason);
      });
    });

    it('should not show the discussion lock notes on an article', () => {
      cy.get('#discussion-lock').should(($discussionLock) => {
        expect($discussionLock).not.to.contain.text(exampleNotes);
      });
    });
  });
});
