describe('Navigation links', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/admin/navigation_links');
      });
    });
  });

  it('should open the add navigation link modal', () => {
    cy.findByText('Add Navigation Link').as('addLinkButton');

    cy.get('@addLinkButton').click();
    cy.findByTestId('modal-container').as('addLinkModal');

    cy.get('@addLinkModal').findByText('Add Navigation Link').should('exist');
    cy.get('@addLinkModal')
      .findAllByRole('button')
      .first()
      .should('have.focus');

    cy.get('@addLinkModal').findByRole('button', { name: /Close/ }).click();
    cy.get('@addLinkButton').should('have.focus');
  });

  it('should open the edit navigation link modal', () => {
    cy.findAllByText('Edit Link').first().as('editLinkButton');

    cy.get('@editLinkButton').click();
    cy.findByTestId('modal-container').as('editLinkModal');

    cy.get('@editLinkModal').findByText('Edit Link').should('exist');
    cy.get('@editLinkModal')
      .findAllByRole('button')
      .first()
      .should('have.focus');

    cy.get('@editLinkModal').findByRole('button', { name: /Close/ }).click();
    cy.get('@editLinkButton').should('have.focus');
  });
});
