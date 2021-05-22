describe('Moderation navigation', () => {
  describe('mobile screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.viewport('iphone-6');
          cy.visit('/mod');
        });
      });
    });

    it('shows all topics by default', () => {
      cy.findByRole('navigation', {
        name: 'Mod center inbox navigation',
      }).within(() => {
        cy.findByRole('link', { name: 'All topics' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
        cy.findByRole('link', { name: '#tag1' }).should(
          'have.attr',
          'aria-current',
          '',
        );
      });
    });

    it('should switch tab to a tag', () => {
      cy.findByRole('navigation', {
        name: 'Mod center inbox navigation',
      }).within(() => {
        cy.findByRole('link', { name: '#tag1' }).as('tag1');
        cy.get('@tag1').should('have.attr', 'aria-current', '');
        cy.get('@tag1').click();
      });

      //   Get a new handle to element as a new page has loaded
      cy.findByRole('link', { name: '#tag1' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });
});
