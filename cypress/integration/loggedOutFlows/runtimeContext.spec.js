describe('Runtime Context', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should detect the current context and set data-runtime attr', () => {
    // Visit the site
    cy.visit('/');

    // Check the body's data-runtime attribute
    cy.get('body').should('have.attr', 'data-runtime');
  });
});
