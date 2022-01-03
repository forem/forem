describe('Search form', () => {
  it('should show results when search button is pressed', () => {
    cy.visit('/');

    cy.findByRole('textbox', { name: /search/i }).type('test');
    cy.findByRole('button', { name: /search/i }).click();

    cy.url().should('include', '/search?q=test');
    cy.findByRole('heading', { name: 'Test article' }).should('exist');
  });
});
