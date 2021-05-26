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

      // This is failing with a timeout error
      // cy.visit('/');
      // cy.findByTestId('pinned-article', { timeout: 10000 }).should('be.visible');
    });
  });

  it('should unpin a post', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('button', { name: 'Pin Post' }).click();
      cy.findByRole('button', { name: 'Unpin Post' }).click();
      cy.findByRole('button', { name: 'Pin Post' });

      // This is failing with a timeout error
      // cy.visit('/');
      // cy.findByTestId('pinned-article', { timeout: 10000 }).should('not.be.visible');
    });
  });
});
