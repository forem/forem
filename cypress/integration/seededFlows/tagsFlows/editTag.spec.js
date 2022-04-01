describe('Edit tag', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/t/tag1/edit');
    });
  });

  it('enhances the color input with the rich ColorPicker', () => {
    // Both a button and an input should be available
    cy.findByRole('button', { name: 'Tag color' }).as('popoverButton');
    cy.findByRole('textbox', { name: 'Tag color' }).as('input');

    // Input should be pre-filled with the current bg_color_hex
    cy.get('@input').should('have.value', '#672c99');
    // Button should open and close a picker
    cy.get('@popoverButton')
      .should('have.attr', 'aria-expanded', 'false')
      .click()
      .should('have.attr', 'aria-expanded', 'true');

    cy.findByLabelText('Color').should('be.visible');

    cy.get('@popoverButton')
      .click()
      .should('have.attr', 'aria-expanded', 'false');
    cy.findByLabelText('Color').should('not.be.visible');
  });

  it('changes the tag color', () => {
    // Make sure the enhanced component is now visible
    cy.findByRole('button', { name: 'Tag color' });

    cy.findByRole('textbox', { name: 'Tag color' }).enterIntoColorInput(
      'ababab',
    );
    cy.findByRole('button', { name: 'Save' }).click();

    // Wait for confirmation
    cy.findByText(/Tag successfully updated!/);
    cy.findByRole('textbox', { name: 'Tag color' }).should(
      'have.value',
      '#ababab',
    );
  });
});
