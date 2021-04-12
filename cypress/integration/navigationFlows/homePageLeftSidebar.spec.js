describe('Home Page Left Sidebar', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should open the "More" links', () => {
    // Go to home page
    cy.visit('/');

    // Click on the More... button in the nav
    cy.get('#page-content-inner').within(() => {
      cy.findByText('More...').click().should('not.be.visible');
      cy.findByText('Nav link 5').should('be.visible');
      // visit another page with InstantClick
      cy.findByText('Nav link 0').click();
    });

    // go back to the homepage with InstantClick
    cy.intercept('/?i=i').as('homepage');
    cy.findAllByText('Home').last().click();
    cy.wait('@homepage');

    // repeat and assert
    cy.get('#page-content-inner').within(() => {
      cy.findByText('More...').click().should('not.be.visible');
      cy.findByText('Nav link 5').should('be.visible');
    });
  });
});
