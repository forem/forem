describe('Display Ads', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/customization/display_ads');

      cy.findByRole('table').within(() => {
        cy.findByRole('button', { name: 'Destroy' }).click();
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

      cy.findByRole('table').within(() => {
        cy.findByRole('button', { name: 'Destroy' }).should('be.visible');
      });
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
            'Display Ad has been deleted!',
          );
        });

        cy.findByRole('table').within(() => {
          cy.findByRole('button', { name: 'Destroy' }).should('not.exist');
        });
      });
    });

    it('generates error message when remove action fails', () => {
      cy.intercept('DELETE', '/admin/customization/display_ads/**', {
        statusCode: 422,
        body: {
          error: 'Something went wrong with deleting the Display Ad.',
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
            .contains('Something went wrong with deleting the Display Ad.')
            .should('be.visible');
        });

        cy.findByRole('table').within(() => {
          cy.findByRole('button', { name: 'Destroy' }).should('be.visible');
        });
      });
    });
  });
});
