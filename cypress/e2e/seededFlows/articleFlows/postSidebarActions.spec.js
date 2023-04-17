describe('Post sidebar actions', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

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

  it('should open and close the share menu for the post', () => {
    // Check dropdown is closed by asserting the first option isn't visible
    cy.findByRole('button', { name: /^Copy link$/i }).should('not.exist');

    cy.findByRole('button', { name: /^Share post options$/i }).as(
      'dropdownButton',
    );
    cy.get('@dropdownButton').click();
    cy.findByRole('button', { name: /^Copy link$/i }).as('copyPostUrlButton');
    cy.get('@copyPostUrlButton').should('have.focus');
    cy.findByRole('link', { name: /^Share to Twitter$/i });
    cy.findByRole('link', { name: /^Share to LinkedIn$/i });
    cy.findByRole('link', { name: /^Share to Reddit$/i });
    cy.findByRole('link', { name: /^Share to Hacker News$/i });
    cy.findByRole('link', { name: /^Share to Facebook$/i });
    // There is a report abuse link at the bottom of the post too
    cy.findAllByRole('link', { name: /^Report Abuse$/i }).should(
      'have.length',
      2,
    );

    cy.get('@dropdownButton').click();

    // Check dropdown is closed by asserting the first option isn't visible
    cy.get('@copyPostUrlButton').should('not.be.visible');
  });

  it('should close the options dropdown on Escape press, returning focus', () => {
    cy.findByRole('button', { name: /^Share post options$/i }).as(
      'dropdownButton',
    );
    cy.get('@dropdownButton').click();
    cy.findByRole('button', { name: /^Copy link$/i }).as('copyPostUrlButton');
    cy.get('@copyPostUrlButton').should('have.focus');
    cy.get('body').type('{esc}');
    cy.get('@copyPostUrlButton').should('not.be.visible');
    cy.get('@dropdownButton').should('have.focus');
  });

  it('should copy to clipboard and display clipboard copy announcer until the dropdown is next closed', () => {
    cy.findByRole('button', { name: /^Share post options$/i }).as(
      'dropdownButton',
    );
    cy.get('@dropdownButton').click();
    cy.findByRole('button', { name: /^Copy link$/i }).as('copyPostUrlButton');
    cy.findByText('Copied to Clipboard').should('not.be.visible');
    cy.get('@copyPostUrlButton').click();
    cy.findByText('Copied to Clipboard').should('be.visible');

    // Check the clipboard was populated
    cy.assertValueCopiedToClipboard('/article_editor_v2_user/');

    // Close the dropdown, and reopen it to check the message has disappeared
    cy.get('@dropdownButton').click();
    cy.get('@dropdownButton').click();
    cy.findByText('Copied to Clipboard').should('not.be.visible');
  });

  it('should jump to comments when the button is pressed', () => {
    // Article with comments
    cy.visit('/admin_mcadmin/test-article-slug');

    cy.findByRole('heading', { name: 'Test article' })
      .as('articleSection')
      .should('be.visible');
    cy.get('#comments', { hidden: true }).as('commentsSection');

    cy.findByRole('button', { name: 'Jump to Comments' }).click();

    // TODO: Why is the scrolling not working as it should?
    cy.findByText(/Top Comments/i).should('be.visible');
    cy.get('@articleSection').should((element) => {
      // Element is above viewport, out of view
      expect(element[0].getBoundingClientRect().bottom).lessThan(0);
    });
    cy.get('@commentsSection').should((element) => {
      // Element is at top of viewport (with some leeway)
      expect(element[0].getBoundingClientRect().top).lessThan(50);
    });
  });
});
