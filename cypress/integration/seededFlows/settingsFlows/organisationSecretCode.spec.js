describe('organisation secret code', () => {
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
});
