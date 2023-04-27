describe('Notification initialization', () => {
  describe('Home page notifications', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/notificationsUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/');
        });
      });
    });

    it('Shows the notification count', () => {
      cy.get('#notifications-link').find('span').as('pan');

      cy.get('@pan').should('have.text', '2');
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

    it('Shows the notifications marked as read', () => {
      cy.get('#notifications-link').find('span').as('pan');

      cy.get('@pan').should('have.value', '');
    });

    it('initializes reactions', () => {
      cy.get('.reaction-button').should('exist');
      cy.get('.reacted').should('exist');
    });
  });
});
