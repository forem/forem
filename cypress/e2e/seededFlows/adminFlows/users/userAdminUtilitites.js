/**
 * E2E helper function for user admin tests that validates the correct flash success message appears
 *
 * @param {string} [message="User has been updated"] The expected flash message text
 */
export function verifyAndDismissUserUpdatedMessage(
  message = 'User has been updated',
) {
  cy.findByTestId('flash-success')
    .as('success')
    .then((element) => {
      expect(element.text().trim()).equal(message);
    });

  cy.get('@success').within(() => {
    cy.findByRole('button', { name: 'Dismiss message' })
      .should('have.focus')
      .click();
  });

  cy.findByTestId('flash-success').should('not.exist');
}
