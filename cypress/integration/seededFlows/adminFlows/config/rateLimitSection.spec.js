describe('Campaign Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('rate limit settings', () => {
    it('can change for how many days a user is considered new', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_rate_limit').as('rateLimitSectionForm');

        cy.get('@rateLimitSectionForm')
          .findByText('Rate limits and anti-spam')
          .click();

        cy.get('@rateLimitSectionForm')
          .get('#settings_rate_limit_user_considered_new_days')
          .clear()
          .type('42');

        cy.get('@rateLimitSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Successfully updated settings.',
          );
        });

        cy.get('#settings_rate_limit_user_considered_new_days').should(
          'have.value',
          '42',
        );
      });
    });

    it('generates error message when update fails', () => {
      cy.intercept('POST', '/admin/settings/rate_limits', {
        error: 'some error msg',
      });
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_rate_limit').as('rateLimitSectionForm');

        cy.get('@rateLimitSectionForm')
          .findByText('Rate limits and anti-spam')
          .click();

        cy.get('@rateLimitSectionForm')
          .get('#settings_rate_limit_user_considered_new_days')
          .clear()
          .type('42');

        cy.get('@rateLimitSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should('have.text', 'some error msg');
        });
      });
    });
  });
});
