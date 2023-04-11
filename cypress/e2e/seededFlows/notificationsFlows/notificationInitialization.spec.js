describe('Notification initialization', () => {
  describe('Notification initialization', () => {
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
