describe('View details link on article list page admin area', () => {
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
          cy.visit('/admin/content_manager/articles');
        });
      });
    });
  });

  it('should contain view details button with correct link', () => {
    cy.findAllByRole('link', { name: 'View details' }).each(($link) => {
      const href = $link.attr('href');
      const regex = /\/(\d+)/; // Regular expression to match any number in the URL
      expect(href).to.match(regex);
    });
  });

  it('should not details view details button on individual article page', () => {
    cy.createArticle({
      title: 'A new article',
      tags: ['beginner', 'ruby', 'go'],
      content: `This is another test article's contents.`,
      published: true,
    }).then((response) => {
      cy.visit(`/admin/content_manager/articles/${response.body.id}`);
    });

    cy.findAllByRole('link', { name: 'View details' }).should('not.exist');
  });
});
