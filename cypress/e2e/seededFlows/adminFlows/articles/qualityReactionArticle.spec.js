describe('View details link on article list page admin area', () => {
  let articleId;
  let articlePath;
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
          articlePath = response.body.current_state_path;
          cy.visit(`/${articlePath}`);
          cy.findByRole('button', { name: 'Moderation' }).click();
          cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
            cy.findByText('High Quality').click();
          });
          cy.visit(`/admin/content_manager/articles/${articleId}`);
        });
      });
    });
  });

  it('should validate the vomit reaction count', () => {
    cy.findByLabelText('Vomit')
      .should('exist')
      .should(($count) => {
        const reactionCount = $count.text();
        expect(reactionCount).to.match(/^\d+$/); // Assert that the reaction count is a positive number
      });
  });
});
