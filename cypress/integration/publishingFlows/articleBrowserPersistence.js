describe('Article Editor', () => {
  describe('v1 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/new');
        });
      });
    });

    describe(`revert changes`, () => {
      it('should revert to the initial v1 editor template if it is a new article', () => {
        cy.findByTestId('article-form').as('articleForm');

        cy.get('@articleForm')
          .findByLabelText('Post Content')
          .as('postContent')
          .clear()
          .type(
            `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`,
          );
        cy.get('@postContent').should(
          'have.value',
          `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`,
        );

        cy.findByRole('button', { name: /^Revert new changes$/i }).click();
        cy.get('@postContent').should(
          'have.value',
          `---\ntitle: \npublished: false\ndescription: \ntags: \n//cover_image: https://direct_url_to_image.jpg\n---\n\n`,
        );
      });

      it('should revert to the previously saved version of the article if the article was previously edited', () => {
        cy.createArticle({
          content: `---\ntitle: Test Article\npublished: false\ndescription: \ntags: beginner, ruby, go\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is a test article's contents.`,
          published: true,
          editorVersion: 'v1',
        }).then((response) => {
          cy.visit(response.body.current_state_path);

          cy.findByText(/^Edit$/i).click();

          cy.findByTestId('article-form').as('articleForm');

          cy.get('@articleForm')
            .findByLabelText('Post Content')
            .as('postContent')
            .should(
              'have.value',
              `---\ntitle: Test Article\npublished: false\ndescription: \ntags: beginner, ruby, go\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is a test article's contents.`,
            )
            .clear()
            .type(
              `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`,
            );
          cy.get('@postContent').should(
            'have.value',
            `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`,
          );

          cy.findByRole('button', { name: /^Revert new changes$/i }).click();
          cy.get('@postContent').should(
            'have.value',
            `---\ntitle: Test Article\npublished: false\ndescription: \ntags: beginner, ruby, go\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is a test article's contents.`,
          );
        });
      });
    });
  });

  describe('v2 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV2User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/new');
        });
      });
    });

    describe(`revert changes`, () => {
      it('should revert to empty content if it is a new article', () => {
        cy.findByTestId('article-form').as('articleForm');

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
          .type('This is some text that should be reverted');

        cy.get('@postTitle').should(
          'have.value',
          'This is some title that should be reverted',
        );
        cy.get('@postTags').should('have.value', 'tag1, tag2, tag3');
        cy.get('@postContent').should(
          'have.value',
          'This is some text that should be reverted',
        );

        cy.findByRole('button', { name: /^Revert new changes$/i }).click();

        cy.get('@postTitle').should('have.value', '');
        cy.get('@postTags').should('have.value', '');
        cy.get('@postContent').should('have.value', '');
      });

      it('should revert to the previously saved version of the article if the article was previously edited', () => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.visit(response.body.current_state_path);

          cy.findByText(/^Edit$/i).click();

          cy.findByTestId('article-form').as('articleForm');

          cy.get('@articleForm')
            .findByLabelText(/^Post Title$/i)
            .as('postTitle')
            .should('have.value', 'Test Article')
            .clear()
            .type('This is some title that should be reverted');
          cy.get('@articleForm')
            .findByLabelText(/^Post Tags$/i)
            .as('postTags')
            .should('have.value', 'beginner, ruby, go')
            .clear()
            .type('tag1, tag2, tag3');
          cy.get('@articleForm')
            .findByLabelText(/^Post Content$/i)
            .as('postContent')
            .should('have.value', `This is a test article's contents.`)
            .clear()
            .type('This is some text that should be reverted');

          cy.get('@postTitle').should(
            'have.value',
            'This is some title that should be reverted',
          );
          cy.get('@postTags').should('have.value', 'tag1, tag2, tag3');
          cy.get('@postContent').should(
            'have.value',
            'This is some text that should be reverted',
          );

          cy.findByRole('button', { name: /^Revert new changes$/i }).click();

          cy.get('@postTitle').should('have.value', 'Test Article');
          cy.get('@postTags').should('have.value', 'beginner, ruby, go');
          cy.get('@postContent').should(
            'have.value',
            `This is a test article's contents.`,
          );
        });
      });
    });
  });
});
