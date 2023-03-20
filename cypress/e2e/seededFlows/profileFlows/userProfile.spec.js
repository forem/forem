describe('User Profile', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/Admin_McAdmin');
    });
  });

  it("should show the relevant sections when clicking on the 'more info button' on mobile", () => {
    cy.get('@user').then((user) => {
      // The 'more info' button is only for the mobile view
      cy.viewport('iphone-x');
      cy.findByRole('button', {
        name: `More info about @${user.username}`,
      }).click();

      cy.get('.js-user-info').contains('Organizations').should('be.visible');

      cy.get('.js-user-info').contains('Badges').should('be.visible');

      cy.get('.js-user-info').contains('posts published').should('be.visible');

      cy.get('.js-user-info').contains('comments written').should('be.visible');

      cy.get('.js-user-info').contains('tags followed').should('be.visible');
    });
  });
});
