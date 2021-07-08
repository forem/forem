describe('Delete listing', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.viewport('macbook-16');

    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/listings/dashboard');
    });
  });

  it('deletes a listing', () => {
    cy.findByRole('main')
      .findByRole('heading', { name: 'Listing title' })
      .should('exist');

    cy.findByRole('link', { name: 'Delete' }).click();

    // Wait until the confirmation page loads
    cy.findByRole('heading', {
      name: 'Are you sure you want to delete this listing?',
    });

    cy.findByRole('main')
      .findByRole('button', { name: /^Delete$/i })
      .click();

    // Wait for the form to submit and the user to be returned to the dashboard
    cy.findByRole('heading', {
      name: 'Are you sure you want to delete this listing?',
    }).should('not.exist');

    cy.findByRole('main')
      .findByRole('heading', { name: 'Listing title' })
      .should('not.exist');
  });
});
