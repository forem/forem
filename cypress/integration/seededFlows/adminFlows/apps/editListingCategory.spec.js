describe('Edit listing category', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.enableFeatureFlag('listing_feature');

    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/apps/listings');
    });
  });

  it('Navigate to a listing category and change the social preview color', () => {
    cy.findByRole('link', { name: 'Listing Categories' }).click();
    cy.findByRole('link', { name: 'Edit' }).click();

    // Both a button and an input should exist
    cy.findByRole('button', { name: 'Social preview color' });
    cy.findByRole('textbox', {
      name: 'Social preview color',
    }).enterIntoColorInput('#32a852');

    cy.findByRole('button', { name: 'Update Listing Category' }).click();
    cy.findByText('Listing Category has been updated!').should('exist');
    // Check the table entry reflects the new color
    cy.findByRole('cell', { name: '#32a852' });
  });
});
