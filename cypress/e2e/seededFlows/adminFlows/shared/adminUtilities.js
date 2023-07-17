/**
 * E2E helper function for user admin tests that validates the correct flash notice message appears
 *
 * @param {string} [message] The expected flash message text
 * @param {string} [flashTypeId] The id of the flash message type. e.g 'flash-success', 'flash-settings_notice'
 */
export function verifyAndDismissFlashMessage(message, flashTypeId) {
  cy.findByTestId(flashTypeId)
    .as('flash-message')
    .then((element) => {
      expect(element.text().trim()).equal(message);
    });

  cy.get('@flash-message').within(() => {
    cy.findByRole('button', { name: 'Dismiss message' })
      .should('have.focus')
      .click();
  });

  cy.findByTestId(flashTypeId).should('not.exist');
}
