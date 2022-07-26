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
            cy.visitAndWaitForUserSideEffects(
              `${response.body.current_state_path}/manage`,
            );
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
              cy.visitAndWaitForUserSideEffects(articlePath);
            });
          });
        });
      });
    });

    it('should show the new comment box', () => {
      cy.get('#new_comment').should('exist');
    });

    it('should not show a discussion lock', () => {
      cy.get('#discussion-lock').should('not.exist');
    });

    it('should show reply button on comments on the Article page', function () {
      cy.get(`[data-testid="reply-button-${this.commentId}"]`).should(
        'be.visible',
      );
    });

    it('should show reply button on comments on a Comment page', function () {
      cy.visit(this.commentUrl);
      cy.get(`[data-testid="reply-button-${this.commentId}"]`).should(
        'be.visible',
      );
    });

    it('should show the new comment box on the legacy Comment page', function () {
      cy.visit(`${this.articlePath}/comments`);
      cy.get('#new_comment').should('be.visible');
    });

    it('should show reply button on comments on the legacy Comment page', function () {
      cy.visit(`${this.articlePath}/comments`);
      cy.get(`[data-testid="reply-button-${this.commentId}"]`).should(
        'be.visible',
      );
    });
  });
});
