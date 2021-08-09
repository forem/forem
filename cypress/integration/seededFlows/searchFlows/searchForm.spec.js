describe('Search form', () => {
  it('should show results when search button is pressed', () => {
    cy.visit('/');

    cy.findByRole('textbox', { name: /search/i }).type('test');
    cy.get('#header-search').get('button').click();

    cy.url().should('include', '/search?q=test');
  });
});
