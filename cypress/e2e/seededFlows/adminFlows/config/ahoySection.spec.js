describe('Ahoy Analytics Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.updateAdminAuthConfig(user.username);
      });
    });
  });

  describe('ahoy analytics setting', () => {
    it('persists the config when updated', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('ahoyAnalyticsForm').as('ahoyAnalyticsForm');

        cy.get('@ahoyAnalyticsForm').findByText('Ahoy Analytics').click();

        cy.get('#settings_general_ahoy_tracking').should('not.be.checked');

        cy.get('@ahoyAnalyticsForm')
          .get('#settings_general_ahoy_tracking')
          .click();

        cy.get('@ahoyAnalyticsForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Successfully updated settings.',
          );
        });

        cy.get('#settings_general_ahoy_tracking').should('be.checked');
      });
    });

    it('generates error message when update fails', () => {
      cy.intercept('POST', 'admin/settings/general_settings', {
        error: 'some error msg',
      });
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('ahoyAnalyticsForm').as('ahoyAnalyticsForm');

        cy.get('@ahoyAnalyticsForm').findByText('Ahoy Analytics').click();

        cy.get('#settings_general_ahoy_tracking').should('not.be.checked');

        cy.get('@ahoyAnalyticsForm')
          .get('#settings_general_ahoy_tracking')
          .click();

        cy.get('@ahoyAnalyticsForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should('have.text', 'some error msg');
        });
      });
    });
  });
});
