describe('Post Editor', () => {
  function getPostContent() {
    return cy.get('@articleForm').findByLabelText(/^Post Content$/i);
  }

  describe('v1 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    describe(`revert changes`, () => {
      it('should revert to the initial v1 editor template if it is a new post', () => {
        const initialContent = `---\ntitle: \npublished: false\ndescription: \ntags: \n//cover_image: https://direct_url_to_image.jpg\n---\n\n`;
        const updatedContent = `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`;

        cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

        // Fill out the title, tags, and content for an post.
        getPostContent().clear();

        // Clearing out the whole content area as this seemed simpler than finding where to add the fields in the v1 editor
        getPostContent().click();
        getPostContent()
          // The v1 editor has all the post info in one textarea
          .type(updatedContent, { force: true })
          .should('have.value', updatedContent);

        cy.findByRole('button', { name: /^Revert new changes$/i }).click();

        // The post editor should reset to it's initial values
        getPostContent().should('have.value', initialContent);
      });

      it('should revert to the previously saved version of the post if the post was previously edited', () => {
        // Create an post and edit it.
        const initialContent = `---\ntitle: Test Post\npublished: false\ndescription: \ntags: beginner, ruby, go\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is a Test Post's contents.`;
        const updatedContent = `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`;

        cy.createArticle({
          content: initialContent,
          published: true,
          editorVersion: 'v1',
        }).then((response) => {
          const { baseUrl } = Cypress.config();
          cy.intercept(
            baseUrl.replace(/\/$/, '') +
              `${response.body.current_state_path.replace(
                /\?.+$/,
                '',
              )}/edit?i=i`,
          ).as('editPage');

          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);

          cy.findByRole('link', { name: /^Edit$/i })
            .should('be.visible')
            .click();
          cy.wait('@editPage');

          cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

          getPostContent()
            .should('have.value', initialContent)

            // Clearing out the whole content area as this seemed simpler than finding where to add the fields in the v1 editor
            .clear();
          // Update the title, tags, and content for an post.
          getPostContent().click();
          getPostContent().type(updatedContent, { force: true });
          getPostContent().should('have.value', updatedContent);

          cy.findByRole('button', { name: /^Revert new changes$/i }).click();

          // The post editor should reset to it's saved version from the server that was initially loaded into the editor.
          getPostContent().should('have.value', initialContent);
        });
      });

      it('should not revert changes in the editor if the member clicks cancel in the confirmation dialog', () => {
        const updatedContent = `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`;

        cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

        // Fill out the title, tags, and content for an post.
        getPostContent().clear();

        // Clearing out the whole content area as this seemed simpler than finding where to add the fields in the v1 editor
        getPostContent().click();
        getPostContent()
          // The v1 editor has all the post info in one textarea
          .type(updatedContent, { force: true })
          .should('have.value', updatedContent);

        cy.findByRole('button', {
          name: /^Revert new changes$/i,
        }).click();

        cy.on('window:confirm', () => false);

        // The post editor should reset to it's initial values
        getPostContent().should('have.value', updatedContent);
      });
    });
  });

  describe('v2 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV2User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    describe(`revert changes`, () => {
      it('should revert to empty content if it is a new post', () => {
        cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

        // Fill out the title, tags, and content for an post.
        cy.get('@articleForm')
          .findByLabelText(/^Post Title$/i)
          .as('postTitle')
          .type('This is some title that should be reverted');
        cy.get('@articleForm')
          .findByLabelText(/^Post Tags$/i)
          .as('postTags')
          .type('tag1, tag2, tag3');
        cy.get('@articleForm')
          .findByLabelText(/^Post Content$/i)
          .as('postContent')
          .type('This is some text that should be reverted', { force: true });

        cy.get('@postTitle').should(
          'have.value',
          'This is some title that should be reverted',
        );
        cy.get('@postTags').should('have.value', 'tag1, tag2, tag3');
        getPostContent().should(
          'have.value',
          'This is some text that should be reverted',
        );

        cy.findByRole('button', { name: /^Revert new changes$/i }).click();

        // The post editor should reset to it's initial values
        // NOTE: The aliases for the title and tags input are not being used because the DOM nodes
        // are no longer the same reference after reverting changes in the editor.
        cy.get('@articleForm')
          .findByLabelText(/^Post Title$/i)
          .should('have.value', '');
        cy.get('@articleForm')
          .findByLabelText(/^Post Tags$/i)
          .as('postTags')
          .should('have.value', '');
        getPostContent().should('have.value', '');
      });

      it('should revert to the previously saved version of the post if the post was previously edited', () => {
        // Create an post and edit it.
        cy.createArticle({
          title: 'Test Post',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a Test Post's contents.`,
          published: true,
        }).then((response) => {
          const { baseUrl } = Cypress.config();
          cy.intercept(
            baseUrl.replace(/\/$/, '') +
              `${response.body.current_state_path}/edit?i=i`,
          ).as('editPage');

          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);

          cy.findByRole('link', { name: /^Edit$/i })
            .should('be.visible')
            .click();
          cy.wait('@editPage');

          cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

          // Update the title, tags, and content for an post.
          cy.get('@articleForm')
            .findByLabelText(/^Post Title$/i)
            .as('postTitle')
            .should('have.value', 'Test Post') // checking for original value first
            .clear()
            .type('This is some title that should be reverted', {
              force: true,
            });

          cy.get('@articleForm')
            .findByLabelText(/^Post Tags$/i)
            .as('postTags')
            .should('have.value', 'beginner, ruby, go') // checking for original value first
            .clear()
            .type('tag1, tag2, tag3');

          getPostContent()
            .should('have.value', `This is a Test Post's contents.`) // checking for original value first
            .clear();
          getPostContent()
            .click()
            .type('This is some text that should be reverted', { force: true });

          cy.get('@postTitle').should(
            'have.value',
            'This is some title that should be reverted',
          );

          cy.get('@postTags').should('have.value', 'tag1, tag2, tag3');

          getPostContent().should(
            'have.value',
            'This is some text that should be reverted',
            { force: true },
          );

          cy.findByRole('button', { name: /^Revert new changes$/i }).click();

          // The post editor should reset to it's saved version from the server that was initially loaded into the editor.
          // NOTE: The aliases for the title and tags input are not being used because the DOM nodes
          // are no longer the same reference after reverting changes in the editor.
          cy.get('@articleForm')
            .findByLabelText(/^Post Title$/i)
            .as('postTags')
            .should('have.value', 'Test Post');
          cy.get('@articleForm')
            .findByLabelText(/^Post Tags$/i)
            .as('postTags')
            .should('have.value', 'beginner, ruby, go');
          getPostContent().should(
            'have.value',
            `This is a Test Post's contents.`,
          );
        });
      });

      it('should not revert changes in the editor if the member clicks cancel in the confirmation dialog', () => {
        cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');
        const title = 'Some Title';
        const tags = 'tag1, tag2, tag3';
        const content = 'This is some text in the body.';

        // Fill out the title, tags, and content for an post.
        cy.get('@articleForm')
          .findByLabelText(/^Post Title$/i)
          .as('postTitle')
          .type(title);
        cy.get('@articleForm')
          .findByLabelText(/^Post Tags$/i)
          .as('postTags')
          .type(tags);
        cy.get('@articleForm')
          .findByLabelText(/^Post Content$/i)
          .as('postContent')
          .type(content, { force: true });

        cy.get('@postTitle').should('have.value', title);
        cy.get('@postTags').should('have.value', tags);
        getPostContent().should('have.value', content);

        cy.findByRole('button', { name: /^Revert new changes$/i }).click();

        cy.on('window:confirm', () => false);

        // The post editor should reset to it's initial values
        // NOTE: The aliases for the title and tags input are not being used because the DOM nodes
        // are no longer the same reference after reverting changes in the editor.
        cy.get('@postTitle').should('have.value', title);
        cy.get('@postTags').should('have.value', tags);
        getPostContent().should('have.value', content);
      });
    });
  });
});
