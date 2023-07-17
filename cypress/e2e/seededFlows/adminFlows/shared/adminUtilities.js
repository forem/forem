/**
 * E2E helper function for user admin tests that validates the correct flash notice message appears
 *
 * @param {string} [message] The expected flash message text
 */
export function verifyAndDismissFlashMessage(message, flashTypeId) {
  cy.findByTestId(flashTypeId)
    .as('notice')
    .then((element) => {
      expect(element.text().trim()).equal(message);
    });

  cy.get('@notice').within(() => {
    cy.findByRole('button', { name: 'Dismiss message' })
      .should('have.focus')
      .click();
  });

  cy.findByTestId(flashTypeId).should('not.exist');
}
