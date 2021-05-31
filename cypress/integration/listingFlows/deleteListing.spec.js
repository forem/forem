describe('Delete listing', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.viewport('macbook-16');

    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createListing({
          title: 'Test Listing',
          content: `This is a test listing's contents.`,
        }).then(() => {
          cy.visit('/listings/dashboard');
        });
      });
    });
  });

  it('deletes a listing', () => {
    cy.findByText('Delete').click();

    cy.findByRole('main').within(() => {
      cy.get('button', { name: /^Delete$/i }).click();
    });

    cy.findByRole('main').within(() => {
      cy.get('[class=dashboard-listings-view]').should('be.empty');
    });
  });
});
