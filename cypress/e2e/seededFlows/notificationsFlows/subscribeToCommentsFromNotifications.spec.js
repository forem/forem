describe('Subscribe to Comments from notifications', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/notificationsUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/notifications');
    });
  });

  it('Subscribes and unsubscribes to comments from notification', () => {
    cy.findByRole('heading', { name: 'Notifications' });

    cy.findByRole('button', { name: 'Subscribe to thread' }).as(
      'subscribeButton',
    );
    cy.get('@subscribeButton').should('have.attr', 'aria-pressed', 'false');
    cy.get('@subscribeButton').should('have.attr', 'data-info', 'null');
    cy.get('@subscribeButton').click();

    cy.findByRole('button', { name: 'Subscribed to thread' }).as(
      'subscribedButton',
    );
    cy.get('@subscribedButton').contains('Subscribed to thread');
    cy.get('@subscribedButton').should('have.attr', 'aria-pressed', 'true');
    cy.get('@subscribedButton').should(
      'have.attr',
      'aria-label',
      'Subscribed to thread',
    );

    cy.get('@subscribedButton').click();

    cy.findByRole('button', { name: 'Subscribed to thread' }).as(
      'subscribedButton',
    );
    cy.get('@subscribeButton').should('have.attr', 'data-info', 'null');
  });
});
