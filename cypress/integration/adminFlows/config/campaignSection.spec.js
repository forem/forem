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
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_campaign').as('campaignSectionForm');

        cy.get('@campaignSectionForm').findByText('Campaign').click();
        cy.get('@campaignSectionForm')
          .findByPlaceholderText('Used at the top of the campaign sidebar')
          .type('example.com/image.png');

        cy.get('@campaignSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@campaignSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText(
          '😭 Validation failed: Sidebar image is not a valid URL',
        ).should('be.visible');
      });
    });

    it('accepts a valid image URL', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_campaign').as('campaignSectionForm');

        cy.get('@campaignSectionForm').findByText('Campaign').click();
        cy.get('@campaignSectionForm')
          .findByPlaceholderText('Used at the top of the campaign sidebar')
          .type('https://example.com/image.png');

        cy.get('@campaignSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@campaignSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

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
