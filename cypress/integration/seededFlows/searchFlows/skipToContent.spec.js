// Regression test for https://github.com/forem/forem/issues/13876
describe('Search on homepage', () => {
  it('Does not show the "Skip to content" link', () => {
    cy.visit('/');

    cy.get('#header-search')
      .get('form')
      .findByPlaceholderText('Search...')
      .type('admin mcadmin{enter}');

    cy.url().should('include', '/search');
    cy.get('.skip-content-link').should('not.be.visible');
  });
});
