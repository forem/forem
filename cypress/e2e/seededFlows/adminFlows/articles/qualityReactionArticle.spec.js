describe('View quality reactions on an individual article', () => {
  let articleId;
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        //cy.visit('/admin_mcadmin/test-article-slug');
        cy.createArticle({
          title: 'Test article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is another test article's contents.`,
          published: true,
        }).then((response) => {
          articleId = response.body.id;
          cy.visit(`/admin/content_manager/articles/${articleId}`);
        });
      });
    });
  });

  it('should not contain any flags', () => {
    cy.findByText('Article has no flags.').should('exist');
  });
});
