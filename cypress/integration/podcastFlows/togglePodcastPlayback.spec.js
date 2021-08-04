describe('Toggle Podcast playback', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should toggle podcast playback', () => {
    cy.visit('/pod');
  });
});
