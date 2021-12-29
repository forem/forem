describe('Toggle Podcast playback', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  xit('should toggle podcast playback', () => {
    // Can't get the first part working

    cy.get('@toggleButton')
      .invoke('attr', 'aria-pressed')
      .should('eq', 'false');
    cy.get('@toggleButton').click();
    cy.get('@toggleButton').invoke('attr', 'aria-pressed').should('eq', 'true');
  });
});
