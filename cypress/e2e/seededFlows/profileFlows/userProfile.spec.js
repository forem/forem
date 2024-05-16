describe('User Profile', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/Admin_McAdmin');
    });
  });

  describe('toggle profile information toggle on mobile', () => {
    it("should show the relevant sections when clicking on the 'more info button'", () => {
      cy.get('@user').then((user) => {
        // The 'more info' button is only for the mobile view
        cy.viewport('iphone-x');
        cy.findByRole('button', {
          name: `More info about @${user.username}`,
        }).click();

        cy.get('.js-user-info').contains('Organizations').should('be.visible');

        cy.get('.js-profile-badges').should('be.visible');

        cy.get('.js-user-info')
          .contains('posts published')
          .should('be.visible');

        cy.get('.js-user-info')
          .contains('comments written')
          .should('be.visible');

        cy.get('.js-user-info').contains('tags followed').should('be.visible');
      });
    });
  });

  describe('toggle profile badges', () => {
    it('should show 12 badges by default if there are more than 12', () => {
      cy.get('.js-profile-badges')
        .findAllByRole('button')
        .should('have.length', 12);
    });

    it('should show a button to show all the badges if there are more than 6', () => {
      cy.findByRole('button', {
        name: 'Show all 13 badges',
      }).should('be.visible');
    });

    it('should show 13 badges when the button is clicked', () => {
      cy.findByRole('button', {
        name: 'Show all 13 badges',
      }).click();
      cy.get('.js-profile-badges')
        .findAllByRole('button')
        .should('have.length', 13);
    });
  });
});
