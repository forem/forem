describe('Delete listing', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.viewport('macbook-16');

    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/listings/dashboard');
      });
    });
  });

  it('deletes a listing', () => {
    cy.findByRole('main')
      .findByRole('heading', { name: 'Listing title' })
      .should('exist');

    cy.findByRole('link', { name: 'Delete' }).click();

    cy.findByRole('main')
      .findByRole('button', { name: /^Delete$/i })
      .click();

    cy.findByRole('main')
      .findByRole('heading', { name: 'Listing title' })
      .should('not.exist');
  });
});
