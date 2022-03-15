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
    cy.findByRole('button', { name: 'Brand color 1' });
    cy.findByRole('textbox', { name: 'Brand color 1' }).as('brandColor1');

    cy.findByRole('button', { name: 'Brand color 2' });
    cy.findByRole('textbox', { name: 'Brand color 2' }).as('brandColor2');

    // Verify that changing the value saves properly
    cy.get('@brandColor1').enterIntoColorInput('ababab');
    cy.get('@brandColor2').enterIntoColorInput('d22a2a');

    cy.findByRole('button', { name: 'Save Profile Information' }).click();
    cy.findByText('Your profile has been updated');

    cy.findByRole('textbox', { name: 'Brand color 1' }).should(
      'have.value',
      '#ababab',
    );
    cy.findByRole('textbox', { name: 'Brand color 2' }).should(
      'have.value',
      '#d22a2a',
    );
  });
});
