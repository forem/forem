describe('Notification navigation', () => {
  describe('mobile screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.viewport('iphone-6');
          cy.visit('/notifications');
        });
      });
    });

    it('should show All by default', () => {
      cy.findByRole('navigation', { name: 'Notifications' }).within(() => {
        cy.findByRole('link', { name: 'All' }).as('all');
        cy.findByRole('link', { name: 'Comments' }).as('comments');
        cy.findByRole('link', { name: 'Posts' }).as('posts');

        cy.get('@all').should('have.attr', 'aria-current', 'page');
        cy.get('@comments').should('have.attr', 'aria-current', '');
        cy.get('@posts').should('have.attr', 'aria-current', '');
      });
    });

    it('should switch to Comments tab', () => {
      cy.findByRole('navigation', { name: 'Notifications' }).within(() => {
        cy.findByRole('link', { name: 'Comments' }).as('comments');
        cy.get('@comments').should('have.attr', 'aria-current', '');
        cy.get('@comments').click();
      });

      cy.url().should('contain', '/comments');
      // Get a fresh handle as we're on a new page
      cy.findByRole('link', { name: 'Comments' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });

    it('should switch to Posts tab', () => {
      cy.findByRole('navigation', { name: 'Notifications' }).within(() => {
        cy.findByRole('link', { name: 'Posts' }).as('posts');
        cy.get('@posts').should('have.attr', 'aria-current', '');
        cy.get('@posts').click();
      });

      cy.url().should('contain', '/posts');
      // Get a fresh handle as we're on a new page
      cy.findByRole('link', { name: 'Posts' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });
});
