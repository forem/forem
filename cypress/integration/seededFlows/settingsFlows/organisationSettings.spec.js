describe('Organisation settings', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/settings/organization');
    });
  });

  it('copies the secret code to clipboard', () => {
    cy.findByRole('textbox', {
      name: 'Organization secret (to be rotated regularly)',
    })
      .invoke('attr', 'value')
      .then(($orgSecretCode) => {
        // Announcer should not be visible
        cy.findAllByRole('alert').should('have.length', 0);
        cy.findByText('Copied to clipboard!').should('not.be.visible');

        cy.findAllByRole('button').first().focus();

        cy.findByRole('button', {
          name: 'Copy organization secret code to clipboard',
        }).click();

        // Announcer should now be visible
        cy.findAllByRole('alert').should('have.length', 1);
        cy.findByText('Copied to clipboard!').should('be.visible');

        // Check the clipboard has been populated with the correct content
        cy.window()
          .its('navigator.clipboard')
          .invoke('readText')
          .should('equal', $orgSecretCode);
      });
  });

  it('updates brand colors', () => {
    // Check buttons exist for changing the color as well as the inputs
    cy.findByRole('button', { name: 'Brand color 1' });
    cy.findByRole('textbox', { name: 'Brand color 1' })
      .should('have.value', '#000')
      .enterIntoColorInput('AD23AD')
      .should('have.value', '#AD23AD');

    cy.findByRole('button', { name: 'Brand color 2' });
    cy.findByRole('textbox', { name: 'Brand color 2' })
      .should('have.value', '#000')
      .enterIntoColorInput('23AD23')
      .should('have.value', '#23AD23');

    cy.findByRole('button', { name: 'Save' }).click();

    cy.findByText('Your organization was successfully updated.');
    cy.findByRole('textbox', { name: 'Brand color 1' }).should(
      'have.value',
      '#AD23AD',
    );

    cy.findByRole('textbox', { name: 'Brand color 2' }).should(
      'have.value',
      '#23AD23',
    );
  });
});
