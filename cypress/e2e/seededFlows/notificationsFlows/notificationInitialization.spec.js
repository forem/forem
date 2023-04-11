describe('Notification initialization', () => {
  describe('Home page notifications', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/notificationsUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user);
      });
    });

    it('Shows the notification count', () => {
      cy.findByRole('heading', { name: 'Notifications' }).as('notification');

      cy.get('@notification').find('span').should('have.text', '');
    });
  });

  describe('Notifications page', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/notificationsUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/notifications');
      });
    });

    it('Shows the notification count', () => {
      cy.findByRole('heading', { name: 'Notifications' }).as('notification');

      cy.get('@notification').find('span').should('have.text', '');
    });
  });
});
