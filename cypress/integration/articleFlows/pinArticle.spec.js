describe('Pin an article', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

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

  it('should pin a post', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('button', { name: 'Pin Post' }).click();

      // check the button has changed to "Unpin Post"
      cy.findByRole('button', { name: 'Unpin Post' });
    });

    cy.visit('/');

    cy.findByRole('main').findByTestId('pinned-article').should('be.visible');
  });

  it('should unpin a post', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('button', { name: 'Pin Post' }).click();
      cy.findByRole('button', { name: 'Unpin Post' }).click();
      cy.findByRole('button', { name: 'Pin Post' });
    });

    cy.visit('/');

    cy.findByRole('main').findByTestId('pinned-article').should('not.exist');
  });
});
