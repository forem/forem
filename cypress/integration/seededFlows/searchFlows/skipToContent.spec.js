describe('Search on homepage', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.visit('/');
  });

  it('Does not show the "Skip to content" link if button is pressed', () => {
    cy.findByRole('search')
      .findByLabelText('Search term')
      .type('admin mcadmin');

    cy.findByRole('button', { name: 'Search' }).click();

    cy.url().should('include', '/search');

    // Make sure the page has loaded before assertion
    cy.findByRole('heading', { name: 'Test article' });
    cy.get('.skip-content-link').should('not.be.visible');
  });

  it('Shows "Skip to content" if search is submitted by Enter press', () => {
    cy.findByRole('search')
      .findByLabelText('Search term')
      .type('admin mcadmin{enter}');

    cy.url().should('include', '/search');
    // Make sure the page has loaded before assertion
    cy.findByRole('heading', { name: 'Test article' });

    cy.get('.skip-content-link').should('be.visible');
    cy.get('.skip-content-link').should('have.focus');
  });
});
