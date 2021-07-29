describe('Preview user profile from article page', () => {
  describe('mobile screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.viewport('iphone-7');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/').then(() => {
          cy.findAllByRole('link', { name: 'Test article' })
            .first()
            .click({ force: true });

          // Wait for page to load
          cy.findByRole('button', { name: 'Share post options' });
        });
      });
    });

    it('should not show a preview profile details button', () => {
      cy.findByRole('button', { name: 'Admin McAdmin profile details' })
        .as('previewCardTrigger')
        .should('not.exist');

      // Check the user profile link is shown instead (there are also some in the user details card at the bottom)
      cy.findAllByRole('link', { name: 'Admin McAdmin' }).should(
        'have.length',
        3,
      );
    });
  });

  describe.skip("Preview profile on another user's article", () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/').then(() => {
          cy.findAllByRole('link', { name: 'Test article' })
            .first()
            .click({ force: true });

          cy.get('[data-follow-clicks-initialized]');
          cy.findByRole('heading', { name: 'Test article' });
        });
      });
    });

    it('should show a toggleable preview card for author byline', () => {
      cy.findAllByRole('button', { name: 'Admin McAdmin profile details' })
        .first()
        .as('previewCardTrigger');

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

      cy.findAllByTestId('profile-preview-card')
        .first()
        .within(() => {
          cy.findByRole('link', {
            name: 'Admin McAdmin',
          }).should('have.focus');

          // Check all the expected user data sections are present
          cy.findByText('Admin user summary');
          cy.findByText('Software developer');
          cy.findByText('Edinburgh');
          cy.findByText('University of Life');

          cy.findByRole('button', { name: 'Follow' }).click();

          // Wait for Follow button to disappear and Following button to be initialized
          cy.findByRole('button', { name: 'Follow' }).should('not.exist');
          cy.findByRole('button', { name: 'Following' });
        });

      // Check we can close the preview dropdown
      cy.get('@previewCardTrigger').click();
      cy.findAllByTestId('profile-preview-card')
        .first()
        .should('not.be.visible');
      cy.get('@previewCardTrigger').should(
        'have.attr',
        'aria-expanded',
        'false',
      );
    });

    it('should show a preview card for comment name', () => {
      cy.findByTestId('comments-container').within(() => {
        cy.findByRole('button', { name: 'Admin McAdmin profile details' }).as(
          'previewCardTrigger',
        );

        cy.get('[data-initialized]');
        cy.get('@previewCardTrigger').click();

        cy.findByTestId('profile-preview-card').within(() => {
          cy.findByRole('link', {
            name: 'Admin McAdmin',
          }).should('have.focus');

          // Check all the expected user data sections are present
          cy.findByText('Admin user summary');
          cy.findByText('Software developer');
          cy.findByText('Edinburgh');
          cy.findByText('University of Life');

          cy.findByRole('button', { name: 'Follow' }).click();

          // Wait for Follow button to disappear and Following button to be initialized
          cy.findByRole('button', { name: 'Follow' }).should('not.exist');
          cy.findByRole('button', { name: 'Following' });
        });
      });
    });

    it('should update any other matching follow buttons when follow CTA is clicked', () => {
      cy.get('[data-initialized]');
      // Click the follow button in the author byline preview
      cy.findAllByRole('button', { name: 'Admin McAdmin profile details' })
        .first()
        .click();

      cy.findAllByTestId('profile-preview-card')
        .first()
        .within(() => {
          cy.findByRole('button', { name: 'Follow' }).click();
          // Confirm the follow button has been updated
          cy.findByRole('button', { name: 'Follow' }).should('not.exist');
          cy.findByRole('button', { name: 'Following' });
        });

      // Check the follow button in the comment author preview card has updated
      cy.findAllByRole('button', { name: 'Admin McAdmin profile details' })
        .last()
        .click();

      cy.findAllByTestId('profile-preview-card')
        .last()
        .findByRole('button', { name: 'Following' });
    });

    it('should detach listeners on preview card close', () => {
      cy.findAllByRole('button', { name: 'Admin McAdmin profile details' })
        .first()
        .as('previewCardTrigger');

      // Make sure button has initialized
      cy.get('[data-initialized]').should('exist');

      // Open the preview
      cy.get('@previewCardTrigger').click();
      cy.get('@previewCardTrigger').should(
        'have.attr',
        'aria-expanded',
        'true',
      );

      // Close by pressing Escape
      cy.get('body').type('{esc}');
      cy.get('@previewCardTrigger').should(
        'have.attr',
        'aria-expanded',
        'false',
      );
      cy.get('@previewCardTrigger').should('have.focus');

      // Focus another item on the page
      cy.findByRole('button', { name: 'Share post options' }).focus();

      // Press Escape again and check the focus isn't reverted back to the dropdown trigger
      cy.get('body').type('{esc}');
      cy.get('@previewCardTrigger').should('not.have.focus');

      // Click on a non-interactive element and check the focus isn't reverted back to the dropdown trigger
      cy.findByRole('heading', { name: 'Test article' }).click();
      cy.get('@previewCardTrigger').should('not.have.focus');
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
            cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
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

  describe('Preview author profile on an organization article', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/');
          cy.findAllByRole('link', { name: 'Organization test article' })
            .first()
            .click({ force: true });
          // Make sure we have arrived on the article page
          cy.findByRole('button', { name: 'Share post options' });
        });
      });
    });

    it('Should show author details in the preview card', () => {
      cy.findByRole('button', { name: 'Admin McAdmin profile details' }).as(
        'profileDetailsButton',
      );
      // Make sure the button is initialized before interacting
      cy.get('[data-initialized]');
      cy.get('@profileDetailsButton').click();
      cy.findByTestId('profile-preview-card').within(() => {
        // Check user fields are present
        cy.findByRole('link', {
          name: 'Admin McAdmin',
        }).should('have.focus');

        cy.findByRole('button', { name: 'Follow' });
        cy.findByText('Admin user summary');
        cy.findByText('Software developer');
        cy.findByText('Edinburgh');
        cy.findByText('University of Life');
      });
    });
  });
});
