describe('Tag index page mobile sidebars', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/').then(() => {
        cy.createArticle({
          title: 'Ruby',
          tags: ['tag1'],
          content: 'This is a test article',
          published: true,
        }).then(() => {
          cy.createArticle({
            title: 'JavaScript??',
            tags: ['tag1', 'discuss'],
            content: 'This is a discussion',
            published: true,
          }).then(() => {
            cy.visit('/t/tag1');
          });
        });
      });
    });

    cy.viewport('iphone-x');
  });

  it('hides the left sidebar in an interactable drawer', () => {
    cy.get('#sidebar-wrapper-left')
      .as('leftSidebar')
      .within(() => {
        // There's a tag-specific "Create Post" button in the left sidebar
        cy.findByRole('link', { name: 'Create Post', hidden: true })
          .as('createPostButton')
          .should('not.be.visible');

        // There is one already-seeded article besides the ones we are creating
        cy.findByText('3 Posts Published', { hidden: true })
          .as('postsCount')
          .should('not.be.visible');
      });

    cy.findByRole('button', { name: 'nav-button-left' }).click();
    cy.get('@createPostButton').should('be.visible');
    cy.get('@postsCount').should('be.visible');

    cy.get('@leftSidebar').within(() => {
      cy.get('.sidebar-bg').click({ force: true });
    });
    cy.get('@createPostButton').should('not.be.visible');
    cy.get('@postsCount').should('not.be.visible');
  });

  it('hides the right sidebar in an interactable drawer', () => {
    cy.get('#sidebar-wrapper-right')
      .as('rightSidebar')
      .within(() => {
        // The right sidebar has discussion threads & follow suggestions for the tag
        cy.findByText('#discuss', { hidden: true })
          .as('discussions')
          .should('not.be.visible');

        cy.findByText('who to follow', { hidden: true })
          .as('followSuggestions')
          .should('not.be.visible');

        cy.findByRole('link', { name: /JavaScript??/, hidden: true })
          .as('discussionThread')
          .should('not.be.visible');
      });

    cy.findByRole('button', { name: 'nav-button-right' }).click();
    cy.get('@discussions').should('be.visible');
    cy.get('@followSuggestions').should('be.visible');
    cy.get('@discussionThread').should('be.visible');

    cy.get('@rightSidebar').within(() => {
      cy.get('.sidebar-bg').click({ force: true });
    });
    cy.get('@discussions').should('not.be.visible');
    cy.get('@followSuggestions').should('not.be.visible');
    cy.get('@discussionThread').should('not.be.visible');
  });
});
