describe('Markdown toolbar', () => {
  beforeEach(() => {
    cy.testSetup();

    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/new');
    });
  });

  it('expands and collapses overflow menu', () => {
    cy.findByRole('button', { name: 'More options' }).as('overflowMenuButton');

    // Check the menu opens on down arrow press
    cy.get('@overflowMenuButton')
      .should('have.attr', 'aria-expanded', 'false')
      .focus()
      .type('{downarrow}')
      .should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('menuitem', { name: 'Underline' })
      .should('be.visible')
      .should('have.focus');

    // Check Escape closes the menu
    cy.get('body').type('{esc}');
    cy.get('@overflowMenuButton')
      .should('have.focus')
      .should('have.attr', 'aria-expanded', 'false');

    // Check clicking toggles the menu
    cy.get('@overflowMenuButton')
      .click()
      .should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('menuitem', { name: 'Underline' })
      .should('be.visible')
      .should('have.focus');

    cy.get('@overflowMenuButton')
      .click()
      .should('have.attr', 'aria-expanded', 'false');
  });

  it('closes overflow menu after formatter button press', () => {
    cy.findByLabelText('Post Content').clear();

    cy.findByRole('button', { name: 'More options' }).as('overflowMenuButton');

    cy.get('@overflowMenuButton').click();
    cy.findByRole('menuitem', { name: 'Underline' }).click();

    cy.get('@overflowMenuButton').should('have.attr', 'aria-expanded', 'false');
    cy.findByRole('menuitem', { name: 'Underline' }).should('not.exist');

    cy.findByLabelText('Post Content')
      .should('have.focus')
      .should('have.value', '<u></u>');
  });

  it('inserts formatting on button press, returning focus to text area with correct cursor position', () => {
    cy.findByLabelText('Post Content').clear();
    cy.findByRole('button', { name: 'Bold' }).click();

    cy.findByLabelText('Post Content')
      .should('have.value', '****')
      .should('have.focus')
      .type('something')
      .should('have.value', '**something**');
  });

  it('cycles button focus using arrow keys', () => {
    cy.findByRole('button', { name: 'Bold' }).as('boldButton');

    cy.get('@boldButton').focus().type('{leftarrow}');
    cy.findByRole('button', { name: 'More options' })
      .should('have.focus')
      .type('{rightarrow}');

    cy.get('@boldButton').should('have.focus');
  });
});
