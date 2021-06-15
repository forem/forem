describe('Preview user profile from article page', () => {
  describe("Preview profile on another user's article", () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/');
          cy.findAllByRole('link', { name: 'Test article' })
            .first()
            .click({ force: true });
          cy.findByRole('heading', { name: 'Test article' });
        });
      });
    });

    it('should show a toggleable preview card', () => {
      cy.findByRole('button', { name: 'Admin McAdmin profile details' }).as(
        'previewCardTrigger',
      );

      // Initializes as unexpanded
      cy.get('@previewCardTrigger').should(
        'have.attr',
        'aria-expanded',
        'false',
      );

      // Check the content opens and manages focus
      cy.get('@previewCardTrigger').click();
      cy.get('@previewCardTrigger').should(
        'have.attr',
        'aria-expanded',
        'true',
      );

      cy.findByTestId('profile-preview-card').within(() => {
        cy.findByRole('link', {
          name: 'Admin McAdmin',
        }).should('have.focus');

        // Check all the expected user data sections are present
        cy.findByText('Admin user summary');
        cy.findByText('Software developer');
        cy.findByText('Edinburgh');
        cy.findByText('University of Life');

        // Check we can follow a user
        cy.findByRole('button', { name: 'Follow' }).click();
        cy.findByRole('button', { name: 'Following' });
      });

      // Check we can close the preview dropdown
      cy.get('@previewCardTrigger').click();
      cy.findByTestId('profile-preview-card').should('not.be.visible');
      cy.get('@previewCardTrigger').should(
        'have.attr',
        'aria-expanded',
        'false',
      );
    });
  });

  describe("Preview profile on user's own article", () => {
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

    it('should show a preview card with Edit profile CTA', () => {
      cy.findByRole('button', {
        name: 'Article Editor v1 User profile details',
      }).as('previewCardTrigger');

      // Initializes as unexpanded
      cy.get('@previewCardTrigger').should(
        'have.attr',
        'aria-expanded',
        'false',
      );

      // Check the content opens and manages focus
      cy.get('@previewCardTrigger').click();
      cy.get('@previewCardTrigger').should(
        'have.attr',
        'aria-expanded',
        'true',
      );

      cy.findByTestId('profile-preview-card').within(() => {
        cy.findByRole('link', {
          name: 'Article Editor v1 User',
        }).should('have.focus');

        // Check Follow option is replaced with Edit profile
        cy.findByRole('button', { name: 'Edit profile' }).click();
      });

      // Check Edit profile directs to correct page
      cy.url().should('contain', '/settings');
      cy.findByRole('heading', {
        name: 'Settings for @article_editor_v1_user',
      });
    });
  });
});
