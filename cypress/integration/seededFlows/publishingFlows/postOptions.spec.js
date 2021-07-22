describe('V2 Editor Post options', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/new');
    });
  });

  describe('New post', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV2User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    it('should show a dropdown of post options when creating a new post', () => {
      cy.findByRole('main').within(() => {
        cy.findByRole('button', { name: 'Post options' }).as('dropdownButton');
        cy.get('@dropdownButton').click();
        // Verify the expected elements are present
        cy.findByRole('heading', { name: 'Post options' });
        cy.findByRole('textbox', { name: 'Canonical URL' }).should(
          'have.focus',
        );
        cy.findByRole('textbox', { name: 'Series' });

        // Verify clicking 'Done' closes the menu
        cy.findByRole('button', { name: 'Done' }).click();
        cy.findByRole('heading', { name: 'Post options' }).should('not.exist');
        cy.get('@dropdownButton').should('have.focus');

        // Verify clicking on the dropdown button also closes the menu
        cy.get('@dropdownButton').click();
        cy.findByRole('heading', { name: 'Post options' });
        cy.get('@dropdownButton').click();
        cy.findByRole('heading', { name: 'Post options' }).should('not.exist');
      });

      // Verify dropdown can be closed by pressing Escape
      cy.get('@dropdownButton').click();
      cy.findByRole('heading', { name: 'Post options' });
      cy.get('body').type('{esc}');
      cy.findByRole('heading', { name: 'Post options' }).should('not.exist');
      cy.get('@dropdownButton').should('have.focus');
    });

    it('should set a canonical URL', () => {
      cy.findByRole('main').within(() => {
        cy.findByRole('button', { name: 'Post options' }).click();
        cy.findByRole('textbox', { name: 'Canonical URL' }).type(
          'http://exampleurl.com',
        );
        cy.findByRole('button', { name: 'Done' }).click();

        // Check the URL has persisted
        cy.findByRole('button', { name: 'Post options' }).click();
        cy.findByDisplayValue('http://exampleurl.com').should('exist');
        cy.findByRole('button', { name: 'Post options' }).click();

        // Add the minimum post content to publish
        cy.findByRole('textbox', { name: 'Post Title' }).type('test title');
        cy.findByRole('textbox', { name: 'Post Content' }).type('test content');
        cy.findByRole('button', { name: 'Publish' }).click();
      });

      // Verify that the canonical URL is used
      cy.findByText('Originally published at').should('exist');
      cy.findByRole('link', { name: 'exampleurl.com' });
    });

    it('should set a series name', () => {
      cy.findByRole('main').within(() => {
        cy.findByRole('button', { name: 'Post options' }).click();
        cy.findByRole('textbox', { name: 'Series' }).type('Example series');
        cy.findByRole('button', { name: 'Done' }).click();

        // Check that the series name has persisted
        cy.findByRole('button', { name: 'Post options' }).click();
        cy.findByDisplayValue('Example series').should('exist');
        cy.findByRole('button', { name: 'Done' }).click();

        // Add the minimum post content to publish
        cy.findByRole('textbox', { name: 'Post Title' }).type('test title');
        cy.findByRole('textbox', { name: 'Post Content' }).type('test content');
        cy.findByRole('button', { name: 'Publish' }).click();
      });

      // Check that the post is part of a series
      cy.findByRole('link', { name: 'Edit' }).click();

      cy.findByRole('button', { name: 'Post options' });
      cy.findByRole('main').within(() => {
        cy.findByRole('button', { name: 'Post options' }).click();
        cy.findByDisplayValue('Example series').should('exist');

        // Check that the Existing series dropdown is now available
        cy.findByRole('combobox', {
          name: 'Select one of the existing series',
        }).select('Example series');
      });
    });
  });

  describe('Edit existing post', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV2User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.createArticle({
            title: 'Post options test article',
            tags: ['beginner', 'ruby', 'go'],
            content: `This is a test article's contents.`,
            published: true,
          }).then(() => {
            cy.visitAndWaitForUserSideEffects('/dashboard');
            cy.findByRole('link', {
              name: 'Edit post: Post options test article',
            }).click();
          });
        });
      });
    });

    it('should show a dropdown of post options when editing an existing post', () => {
      // Make sure we are on the edit post page
      cy.findByDisplayValue('Post options test article');
      cy.findByRole('main').within(() => {
        cy.findByRole('button', { name: 'Post options' }).as('dropdownButton');
        cy.get('@dropdownButton').click();
        // Verify the expected elements are present
        cy.findByRole('heading', { name: 'Post options' });
        cy.findByRole('textbox', { name: 'Canonical URL' }).should(
          'have.focus',
        );
        cy.findByRole('textbox', { name: 'Series' });
        cy.findByRole('button', { name: 'Unpublish post' });

        // Verify clicking 'Done' closes the menu
        cy.findByRole('button', { name: 'Done' }).click();
        cy.findByRole('heading', { name: 'Post options' }).should('not.exist');
        cy.get('@dropdownButton').should('have.focus');

        // Verify clicking on the dropdown button also closes the menu
        cy.get('@dropdownButton').click();
        cy.findByRole('heading', { name: 'Post options' });
        cy.get('@dropdownButton').click();
        cy.findByRole('heading', { name: 'Post options' }).should('not.exist');
      });

      // Verify dropdown can be closed by pressing Escape
      cy.get('@dropdownButton').click();
      cy.findByRole('heading', { name: 'Post options' });
      cy.get('body').type('{esc}');
      cy.findByRole('heading', { name: 'Post options' }).should('not.exist');
      cy.get('@dropdownButton').should('have.focus');
    });

    it('should unpublish a post', () => {
      // Make sure we are on the edit post page
      cy.findByDisplayValue('Post options test article');

      cy.findByRole('main').within(() => {
        cy.findByRole('button', { name: 'Post options' })
          .as('dropdownButton')
          .click();
        cy.findByRole('button', { name: 'Unpublish post' }).click();
      });

      // Verify the 'Unpublished post' banner appears
      cy.findByRole('link', { name: 'Click to edit' });
    });
  });
});
