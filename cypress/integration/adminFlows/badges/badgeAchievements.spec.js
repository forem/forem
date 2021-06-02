describe('Badge Achievements', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/admin/content_manager/badge_achievements');
      });
    });
  });

  it('delete a badge achievement', () => {
    cy.findByText('Remove').as('removeBadgeButton');

    cy.get('@removeBadgeButton').click();

    cy.get('@removeBadgeButton').should('not.exist');
  });
});
