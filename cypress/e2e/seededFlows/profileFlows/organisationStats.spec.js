describe('Check stats from organisation profile page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/bachmanity');
      cy.get('[data-follow-clicks-initialized]');
    });
  });

  it('should show posts published stats', () => {
    cy.findByText('1 post published').should('be.visible');
  });
  it('should show members count', () => {
    cy.findByText('2 members').should('be.visible');
  });
});
