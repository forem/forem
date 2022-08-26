describe('Update profile settings', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/settings');
    });
  });

  it('updates brand colors', () => {
    // Verify both a button and an input exist to update both colors
    cy.findByRole('button', { name: 'Brand color' });
    cy.findByRole('textbox', { name: 'Brand color' }).as('brandColor1');

    // Verify that changing the value saves properly
    cy.get('@brandColor1').enterIntoColorInput('ababab');

    cy.findByRole('button', { name: 'Save Profile Information' }).click();
    cy.findByText('Your profile has been updated');

    cy.findByRole('textbox', { name: 'Brand color' }).should(
      'have.value',
      '#ababab',
    );
  });
});
