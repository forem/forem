describe('New article has empty flags, quality reactions and score', () => {
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

  it('should update url on flag tab click', () => {
    cy.findByRole('link', { name: 'Flags' }).click();
    cy.url().should(
      'contains',
      `/admin/content_manager/articles/${articleId}?tab=flags`,
    );
  });

  it('should update url on quality reactions tab click', () => {
    cy.findByRole('link', { name: 'Quality reactions' }).click();
    cy.url().should(
      'contains',
      `/admin/content_manager/articles/${articleId}?tab=quality_reactions`,
    );
  });

  it('should not contain any flags', () => {
    cy.findByText('Article has no flags.').should('exist');
  });

  it('should not contain quality reactions', () => {
    cy.findByRole('link', { name: 'Quality reactions' }).click();
    cy.findByText('Article has no quality reactions by trusted users.').should(
      'exist',
    );
  });

  it('should display the correct thumb up count', () => {
    cy.get('.flex .crayons-card:nth-child(1) .fs-s').should('contain', '0');
  });

  it('should display the correct thumb down count', () => {
    cy.get('.flex .crayons-card:nth-child(2) .fs-s').should('contain', '0');
  });

  it('should display the correct vomit count', () => {
    cy.get('.flex .crayons-card:nth-child(3) .fs-s').should('contain', '0');
  });

  it('should display the correct score', () => {
    cy.get('.flex .crayons-card:nth-child(4) .fs-s').should('contain', '0');
  });
});
