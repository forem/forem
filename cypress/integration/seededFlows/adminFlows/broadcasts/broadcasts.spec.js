describe('Broadcasts', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/advanced/broadcasts');

      cy.findByRole('table').within(() => {
        cy.findByRole('link', { name: 'Mock Broadcast' }).click();
      });

      cy.findByRole('button', { name: /Destroy/i }).click();
    });
  });

  describe('delete a broadcast', () => {
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

      cy.findByRole('heading', { level: 2, name: 'Mock Broadcast' }).should(
        'be.visible',
      );
    });

    it('should delete the broadcast if confirmation text matches', () => {
      cy.get('@user').then((user) => {
        cy.findByRole('dialog').within(() => {
          cy.get('input').type(
            `My username is @${user.username} and this action is 100% safe and appropriate.`,
          );
          cy.findByRole('button', { name: 'Confirm changes' }).click();
        });

        // testing the redirect after broadcast destroy
        cy.url().should('include', '/admin/advanced/broadcasts?redirected');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Broadcast has been deleted!',
          );
        });

        cy.findByRole('table').within(() => {
          cy.findByRole('link', { name: 'Mock Broadcast' }).should('not.exist');
        });
      });
    });

    it.skip('generates error message when destroy action fails', () => {
      cy.intercept('DELETE', '/admin/advanced/broadcasts/**', {
        statusCode: 422,
        body: {
          error: 'Something went wrong with deleting the broadcast.',
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
            .contains('Something went wrong with deleting the broadcast.')
            .should('be.visible');
        });

        cy.url().should('not.include', '?redirected');

        cy.findByRole('heading', { level: 2, name: 'Mock Broadcast' }).should(
          'be.visible',
        );
      });
    });
  });
});
