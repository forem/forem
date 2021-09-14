describe('Badge Achievements', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/content_manager/badge_achievements');

      cy.findByRole('table').within(() => {
        cy.findByRole('button', { name: 'Remove' }).click();
      });
    });
  });

  describe('delete a badge achievement', () => {
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

        cy.get('button[aria-label="Close"]').click();
      });

      cy.findByRole('table').within(() => {
        cy.findByRole('button', { name: 'Remove' }).should('be.visible');
      });
    });

    it('should remove badge achievement if confirmation text matches', () => {
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
            'Badge achievement has been deleted!',
          );
        });

        cy.findByRole('table').within(() => {
          cy.findByRole('button', { name: 'Remove' }).should('not.exist');
        });
      });
    });

    it('generates error message when remove action fails', () => {
      cy.intercept('DELETE', '/admin/content_manager/badge_achievements/**', {
        statusCode: 422,
        body: {
          error: 'Something went wrong.',
        },
      });

      cy.get('@user').then((user) => {
        cy.findByRole('dialog').within(() => {
          cy.get('input').type(
            `My username is @${user.username} and this action is 100% safe and appropriate.`,
          );
          cy.findByRole('button', { name: 'Confirm changes' }).click();
        });

        cy.findByTestId('errorzone').within(() => {
          cy.findByRole('alert')
            .contains('Something went wrong.')
            .should('be.visible');
        });

        cy.findByRole('table').within(() => {
          cy.findByRole('button', { name: 'Remove' }).should('be.visible');
        });
      });
    });
  });
});
