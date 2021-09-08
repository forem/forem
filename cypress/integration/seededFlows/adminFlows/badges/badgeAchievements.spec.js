describe('Badge Achievements', () => {
  beforeEach(() => {
    cy.testSetup();
    // cy.fixture('users/adminUser.json').as('user');

    // cy.get('@user').then((user) => {
    //   cy.loginAndVisit(user, '/admin/content_manager/badge_achievements');
    // });
  });

  describe('delete a badge achievement', () => {
    it('should display confirmation modal', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/content_manager/badge_achievements');

        cy.findByRole('table').within(() => {
          cy.findByRole('button', { name: 'Remove' }).click();
        });

        cy.get('.crayons-modal__box > header > p')
          .contains('Confirm changes')
          .should('be.visible');
      });
    });
  });
});
