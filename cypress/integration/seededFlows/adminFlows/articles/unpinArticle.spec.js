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
          }).then((response) => {
            cy.visit(`/admin/content_manager/articles/${response.body.id}`);
          });
        });
      });
    });
  });

  it('should not display the "Unpin Post" button by default', () => {
    cy.findByRole('button', { name: 'Unpin Post' }).should('not.exist');
  });

  it('should unpin the pinned article', () => {
    cy.findAllByRole('checkbox', { name: 'Pinned' }).first().check();
    cy.findAllByRole('button', { name: 'Submit' }).first().click();

    cy.findAllByRole('link', { name: 'Unpin Post' }).first().click();

    cy.findAllByRole('link', { name: 'Unpin Post' }).should('not.exist');
    cy.findAllByRole('checkbox', { name: 'Pinned' }).should('not.be.checked');
  });
});
