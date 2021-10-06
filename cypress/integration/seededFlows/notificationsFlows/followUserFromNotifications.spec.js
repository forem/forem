describe('Follow user from notifications', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/notificationsUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/notifications');
    });
  });

  it('Follows and unfollows a user from a follow notification', () => {
    cy.findByRole('heading', { name: 'Notifications' });

    cy.findByRole('button', { name: 'Follow user back: User' }).as(
      'followButton',
    );
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');
    cy.get('@followButton').click();

    cy.get('@followButton').should('have.text', 'Following');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    cy.get('@followButton').click();
    cy.get('@followButton').should('have.text', 'Follow back');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');
  });
});
