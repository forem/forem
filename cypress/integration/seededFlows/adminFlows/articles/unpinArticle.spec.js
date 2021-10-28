describe('Unpin an article from the admin area', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/').then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then(() => {
          cy.createArticle({
            title: 'Test Another Article',
            tags: ['beginner', 'ruby', 'go'],
            content: `This is another test article's contents.`,
            published: true,
          }).then(() => {
            cy.visit('/admin/content_manager/articles');
          });
        });
      });
    });
  });

  it('should not display the "Unpin Post" button by default', () => {
    cy.findByRole('link', { name: 'Unpin Post' }).should('not.exist');
  });

  it('should unpin the pinned article', () => {
    cy.findAllByRole('button', { name: 'Pin Post' }).first().click();

    cy.findAllByRole('link', { name: 'Unpin Post' }).first().click();

    cy.findAllByRole('link', { name: 'Unpin Post' }).should('not.exist');
    cy.findByText(/Pinned post/i).should('not.exist');
  });
});
