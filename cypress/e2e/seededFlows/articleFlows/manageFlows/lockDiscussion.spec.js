describe('Lock discussion', () => {
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
            cy.visitAndWaitForUserSideEffects(
              `${response.body.current_state_path}/manage`,
            );
          });
        });
      });
    });

    it('should allow a user to lock a discussion', () => {
      getDiscussionLockButton().click();

      cy.findByRole('heading', {
        name: 'Are you sure you want to lock the discussion on this post?',
      }).should('exist');

      getDiscussionLockSubmitButton().should('exist').click();
      getDiscussionUnlockButton().should('exist');
    });

    it('should allow a user to supply a reason and notes', () => {
      getDiscussionLockButton().click();
      cy.findByRole('textbox', {
        name: 'Reason for locking the discussion (optional) - this will be publicly displayed',
      }).should('exist');

      cy.findByRole('textbox', {
        name: 'Notes (optional) - this is only visible to you and admins',
      }).should('exist');
    });
  });

  describe('when an article has its discussion locked', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/').then(() => {
          cy.createArticle({
            title: 'Test Article',
            tags: ['beginner', 'ruby', 'go'],
            content: `This is a test article's contents.`,
            published: true,
          }).then((response) => {
            cy.createComment({
              content: 'This is a test comment.',
              commentableId: response.body.id,
              commentableType: 'Article',
            }).then((commentResponse) => {
              cy.wrap(commentResponse.body.url).as('commentUrl');
              cy.wrap(commentResponse.body.id).as('commentId');
            });
            cy.wrap(response.body.current_state_path).as('articlePath');
            cy.get('@articlePath').then((articlePath) => {
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

    it('should not show the new comment box', () => {
      cy.get('#new_comment').should('not.exist');
    });

    it('should not show reply button on comments on the Article page', function () {
      cy.get(`[data-testid="reply-button-${this.commentId}"]`).should(
        'not.exist',
      );
    });

    it('should not show reply button on comments on a Comment page', function () {
      cy.visit(this.commentUrl);
      cy.get(`[data-testid="reply-button-${this.commentId}"]`).should(
        'not.exist',
      );
    });

    it('should not show the new comment box on the legacy Comment page', function () {
      cy.visit(`${this.articlePath}/comments`);
      cy.get('#new_comment').should('not.exist');
    });

    it('should not show reply button on comments on the legacy Comment page', function () {
      cy.visit(`${this.articlePath}/comments`);
      cy.get(`[data-testid="reply-button-${this.commentId}"]`).should(
        'not.exist',
      );
    });
  });
});
