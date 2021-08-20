describe('Toggle Podcast playback', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should toggle podcast playback', () => {
    cy.visit('/pod');
    cy.contains('div', 'Example media | crow call').click();

    cy.findByRole('button', { name: 'Developer on Fire Play podcast' }).as(
      'toggleButton',
    );

    cy.get('@toggleButton')
      .invoke('attr', 'aria-pressed')
      .should('eq', 'false');
    cy.get('@toggleButton').click();
    cy.get('@toggleButton').invoke('attr', 'aria-pressed').should('eq', 'true');
  });
});
