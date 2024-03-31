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

    cy.findByRole('button', { name: 'Subscribe to comments' }).as(
      'subscribeButton',
    );
    cy.get('@subscribeButton').should('have.attr', 'aria-pressed', 'false');
    cy.get('@subscribeButton').should('have.attr', 'data-subscription_id', '');
    cy.get('@subscribeButton').click();

    cy.intercept({ method: 'POST', url: '/comments/subscribe' }).as(
      'subscribePost',
    );
    cy.wait('@subscribePost');

    cy.findByRole('button', { name: 'Subscribed to comments' }).as(
      'subscribedButton',
    );
    cy.get('@subscribedButton').contains('Subscribed to comments');
    cy.get('@subscribedButton').should('have.attr', 'aria-pressed', 'true');
    cy.get('@subscribedButton').should(
      'have.attr',
      'aria-label',
      'Subscribed to comments',
    );

    cy.get('@subscribedButton').click();

    cy.intercept({ method: 'POST', url: '/subscription/unsubscribe' }).as(
      'unsubscribePost',
    );

    // Wait for all the GET requests with path containing /api/customer/ to complete
    cy.wait('@unsubscribePost');

    cy.findByRole('button', { name: 'Subscribe to comments' }).as(
      'noLongerSubscribedButton',
    );
    cy.get('@noLongerSubscribedButton').should(
      'have.attr',
      'data-subscription_id',
      '',
    );
  });
});
