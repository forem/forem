describe('External Service', () => {
  it('Fetches data from an external, running server', () => {
    cy.visit('/external_request');
    cy.get('#external_compliment').should(
      'have.text',
      'Wow, look at you fetch data!'
    );
  });
});
