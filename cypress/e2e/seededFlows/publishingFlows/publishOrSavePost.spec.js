describe('Publish or save a post', () => {
  describe('v1 Editor', () => {
    const validPublishedArticleContent =
      '---\ntitle: Test title\npublished: true\ndescription:\ntags:\n---\nSome content';

    const invalidPublishedArticleContent =
      '---\ntitle: Test title\npublished: true\ndescription:\ntags:\n---\nSome content {%tag %}';

    const validDraftArticleContent =
      '---\ntitle: Test title\npublished: false\ndescription:\ntags:\n---\nSome content';

    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    it('Publishes a post without errors', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Content')
          .clear()
          .type(validPublishedArticleContent);
        cy.findByRole('button', { name: 'Save changes' }).click();
      });
      //   The post should now be published
      cy.findByRole('heading', { name: 'Test title' });
      cy.findByRole('heading', { name: 'Top comments (0)' });
      cy.findByRole('link', { name: 'Edit' });
      cy.findByRole('link', { name: 'Manage' });
      cy.findByRole('link', { name: 'Stats' });
    });

    it('Saves a draft without errors', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Content')
          .clear()
          .type(validDraftArticleContent);
        cy.findByRole('button', { name: 'Save changes' }).click();
      });

      // The Draft view should be shown
      cy.findByText(/Unpublished Post/);
      cy.findByRole('heading', { name: 'Test title' });
      cy.findByRole('link', { name: 'Click to edit' });
    });

    it('Shows an error message when markdown is incorrect', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Content')
          .clear()
          .type(invalidPublishedArticleContent, {
            parseSpecialCharSequences: false,
          });
        cy.findByRole('button', { name: 'Save changes' }).click();
      });

      cy.findByRole('heading', { name: 'Whoops, something went wrong:' });
      // We should still be on the form page,
      // and should be able to edit the broken draft successfully
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Content')
          .clear()
          .type(validDraftArticleContent);
        cy.findByRole('button', { name: 'Save changes' }).click();
      });
      // The Draft view should be shown
      cy.findByText(/Unpublished Post/);
      cy.findByRole('heading', { name: 'Test title' });
      cy.findByRole('link', { name: 'Click to edit' });
    });

    it('Shows an error message when network request fails', () => {
      cy.intercept('POST', '/articles', { statusCode: 500 });
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Content')
          .clear()
          .type(validPublishedArticleContent);
        cy.findByRole('button', { name: 'Save changes' }).click();
      });
      cy.findByRole('heading', { name: 'Whoops, something went wrong:' });
      // We should still be on the form page
      cy.findByRole('form', { name: /^Edit post$/i });
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

    it('Publishes a post without errors', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');
        cy.findByLabelText('Post Content').clear().type('something');
        cy.findByRole('button', { name: 'Publish' }).click();
      });
      //   The post should now be published
      cy.findByRole('heading', { name: 'Test title' });
      cy.findByRole('heading', { name: 'Top comments (0)' });
      cy.findByRole('link', { name: 'Edit' });
      cy.findByRole('link', { name: 'Manage' });
      cy.findByRole('link', { name: 'Stats' });
    });

    it('Saves a draft without errors', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');
        cy.findByLabelText('Post Content').clear().type('something');
        cy.findByRole('button', { name: 'Save draft' }).click();
      });

      // The Draft view should be shown
      cy.findByText(/Unpublished Post/);
      cy.findByRole('heading', { name: 'Test title' });
      cy.findByRole('link', { name: 'Click to edit' });
    });

    it('Shows an error message when publishing with incorrect markdown', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');

        cy.findByLabelText('Post Content').clear().type('{% tag %}', {
          parseSpecialCharSequences: false,
        });
        cy.findByRole('button', { name: 'Publish' }).click();
      });

      cy.findByRole('heading', { name: 'Whoops, something went wrong:' });
      // We should still be on the form page
      cy.findByRole('form', { name: /^Edit post$/i });
      cy.findByRole('button', { name: 'Publish' });
      cy.findByRole('button', { name: 'Save draft' });
    });

    it('Shows an error message when saving draft with incorrect markdown', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');

        cy.findByLabelText('Post Content').clear().type('{% tag %}', {
          parseSpecialCharSequences: false,
        });
        cy.findByRole('button', { name: 'Save draft' }).click();
      });

      cy.findByRole('heading', { name: 'Whoops, something went wrong:' });
      // We should still be on the form page
      cy.findByRole('form', { name: /^Edit post$/i });
      cy.findByRole('button', { name: 'Publish' });
      cy.findByRole('button', { name: 'Save draft' });
    });

    it('Shows an error message when publishing and network request fails', () => {
      cy.intercept('POST', '/articles', { statusCode: 500 });
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');
        cy.findByLabelText('Post Content').clear().type('something');
        cy.findByRole('button', { name: 'Publish' }).click();
      });
      cy.findByRole('heading', { name: 'Whoops, something went wrong:' });
      // We should still be on the form page
      cy.findByRole('form', { name: /^Edit post$/i });
      cy.findByRole('button', { name: 'Publish' });
      cy.findByRole('button', { name: 'Save draft' });
    });

    it('Shows an error message when saving draft and network request fails', () => {
      cy.intercept('POST', '/articles', { statusCode: 500 });
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');
        cy.findByLabelText('Post Content').clear().type('something');
        cy.findByRole('button', { name: 'Save draft' }).click();
      });
      cy.findByRole('heading', { name: 'Whoops, something went wrong:' });
      // We should still be on the form page
      cy.findByRole('form', { name: /^Edit post$/i });
      cy.findByRole('button', { name: 'Publish' });
      cy.findByRole('button', { name: 'Save draft' });
    });

    it('Maintains draft status when editing a draft fails', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');
        cy.findByLabelText('Post Content').clear().type('something');
        cy.findByRole('button', { name: 'Save draft' }).click();
      });

      // Check we are on the draft post page, and choose to edit
      cy.findByText(/Unpublished Post/);
      cy.findByRole('link', { name: 'Click to edit' }).click();

      cy.findByLabelText('Post Content').clear().type('something else');
      cy.intercept('PUT', '/articles/*', { statusCode: 500 });
      cy.findByRole('button', { name: 'Save draft' }).click();

      // We should still be on the form page and see the draft publish/save options
      cy.findByRole('form', { name: /^Edit post$/i });
      cy.findByRole('button', { name: 'Publish' });
      cy.findByRole('button', { name: 'Save draft' });

      // Check post is still draft in dashboard
      cy.visitAndWaitForUserSideEffects('/dashboard');
      cy.findByRole('heading', { name: 'Dashboard' });
      cy.findByRole('link', { name: 'Draft' });
    });

    it('Maintains draft status when publishing a draft fails', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');
        cy.findByLabelText('Post Content').clear().type('something');
        cy.findByRole('button', { name: 'Save draft' }).click();
      });

      // Check we are on the draft post page, and choose to edit and publish
      cy.findByText(/Unpublished Post/);
      cy.findByRole('link', { name: 'Click to edit' }).click();

      cy.findByLabelText('Post Content').clear().type('something else');
      cy.intercept('PUT', '/articles/*', { statusCode: 500 });
      cy.findByRole('button', { name: 'Publish' }).click();

      // We should still be on the form page and see the draft publish/save options
      cy.findByRole('form', { name: /^Edit post$/i });
      cy.findByRole('button', { name: 'Publish' });
      cy.findByRole('button', { name: 'Save draft' });

      // Check post is still draft in dashboard
      cy.visitAndWaitForUserSideEffects('/dashboard');
      cy.findByRole('heading', { name: 'Dashboard' });
      cy.findByRole('link', { name: 'Draft' });
    });

    it('Maintains published status when editing a published post fails', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).within(() => {
        cy.findByLabelText('Post Title').clear().type('Test title');
        cy.findByLabelText('Post Content').clear().type('something');
        cy.findByRole('button', { name: 'Publish' }).click();
      });

      // Wait for published post page, and choose to edit
      cy.findByRole('heading', { name: 'Test title' });
      cy.findByRole('heading', { name: 'Top comments (0)' });
      cy.findByRole('link', { name: 'Edit' }).click();

      cy.findByLabelText('Post Content').clear().type('something else');
      cy.intercept('PUT', '/articles/*', { statusCode: 500 });
      cy.findByRole('button', { name: 'Save changes' }).click();

      // We should still be on the form page and see the draft publish/save options
      cy.findByRole('form', { name: /^Edit post$/i });
      cy.findByRole('button', { name: 'Save changes' });
      cy.findByRole('button', { name: 'Publish' }).should('not.exist');
      cy.findByRole('button', { name: 'Save draft' }).should('not.exist');

      // Check post is still published in dashboard
      cy.visitAndWaitForUserSideEffects('/dashboard');
      cy.findByRole('heading', { name: 'Dashboard' });
      cy.findByRole('link', { name: 'Draft' }).should('not.exist');
    });
  });
});
