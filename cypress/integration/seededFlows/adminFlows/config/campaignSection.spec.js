describe('Campaign Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('sidebar image setting', () => {
    it('rejects an invalid image URL', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_campaign').as('campaignSectionForm');

        cy.get('@campaignSectionForm').findByText('Campaign').click();
        cy.get('@campaignSectionForm')
          .findByPlaceholderText('Used at the top of the campaign sidebar')
          .type('example.com/image.png');

        cy.get('@campaignSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Validation failed: Sidebar image is not a valid URL',
          );
        });
      });
    });

    it('accepts a valid image URL', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_campaign').as('campaignSectionForm');

        cy.get('@campaignSectionForm').findByText('Campaign').click();
        cy.get('@campaignSectionForm')
          .findByPlaceholderText('Used at the top of the campaign sidebar')
          .type('https://example.com/image.png');

        cy.get('@campaignSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Successfully updated settings.',
          );
        });

        // Page reloaded so need to get a new reference to the form.
        cy.get('#new_settings_campaign').as('campaignSectionForm');
        cy.get('#settings_campaign_sidebar_image').should(
          'have.value',
          'https://example.com/image.png',
        );
      });
    });
  });
});
