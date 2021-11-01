describe('Hiding/unhiding comments on an article', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
    });
  });

  describe('Admin visits the article authored by them', () => {
    it('Hides a comment and then unhides it from the same screen', () => {
      cy.findAllByRole('link', { name: 'Test article' })
        .first()
        .click({ force: true });
      cy.findByRole('button', { name: 'Toggle dropdown menu' })
        .click({ force: true })
        .then(() => {
          cy.findByText('Hide').click({ force: true });
        });
      cy.findByRole('button', { name: 'Toggle dropdown menu' }).should(
        'not.be.visible',
      );
      cy.findByRole('img', { name: 'Expand' }).click({ force: true });
      cy.findByRole('button', { name: 'Toggle dropdown menu' })
        .click({ force: true })
        .then(() => {
          cy.findByText('Unhide').click({ force: true });
        });
      cy.findByRole('img', { name: 'Expand' }).should('not.exist');
    });
  });
});
