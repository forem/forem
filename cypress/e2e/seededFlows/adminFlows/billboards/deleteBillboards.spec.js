describe('Delete Display Ads', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/customization/billboards');

      cy.findByRole('table').within(() => {
        cy.contains('Tests Display Ad')
          .closest('tr')
          .findByRole('button', { name: 'Destroy' })
          .as('deleteButton')
          .click({ force: true });
      });
    });
  });

  describe('delete a display ad', () => {
    it('should display confirmation modal', () => {
      cy.findByRole('dialog').contains('Confirm changes').should('be.visible');
    });

    it('should display warning text if confirmation text does not match', () => {
      cy.findByRole('dialog').within(() => {
        cy.get('input').type('Text that does not match.');
        cy.findByRole('button', { name: 'Confirm changes' }).click();

        cy.get('.crayons-notice')
          .contains('The confirmation text did not match.')
          .should('be.visible');

        cy.findByRole('button', { name: 'Close' }).click();
      });

      cy.get('@deleteButton').should('be.visible');
    });

    it('should remove display ad if confirmation text matches', () => {
      cy.get('@user').then((user) => {
        cy.findByRole('dialog').within(() => {
          cy.get('input').type(
            `My username is @${user.username} and this action is 100% safe and appropriate.`,
          );
          cy.findByRole('button', { name: 'Confirm changes' }).click();
        });

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Billboard has been deleted!',
          );
        });

        cy.get('@deleteButton').should('not.exist');
      });
    });

    it('generates error message when remove action fails', () => {
      cy.intercept('DELETE', '/admin/customization/billboards/**', {
        statusCode: 422,
        body: {
          error: 'Something went wrong with deleting the Billboard.',
        },
      });

      cy.get('@user').then((user) => {
        cy.findByRole('dialog').within(() => {
          cy.get('input').type(
            `My username is @${user.username} and this action is 100% safe and appropriate.`,
          );
          cy.findByRole('button', { name: 'Confirm changes' }).click();
        });

        cy.findByTestId('alertzone').within(() => {
          cy.findByRole('alert')
            .contains('Something went wrong with deleting the Billboard.')
            .should('be.visible');
        });

        cy.get('@deleteButton').should('be.visible');
      });
    });
  });
});
