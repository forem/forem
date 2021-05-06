describe('Mascot Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('mascot image setting', () => {
    it('rejects an invalid image URL', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('mascotSectionForm').as('mascotSectionForm');

        cy.get('@mascotSectionForm').findByText('Mascot').click();
        cy.get('@mascotSectionForm')
          .get('#settings_mascot_image_url')
          .clear()
          .type('example.com/image.png');

        cy.get('@mascotSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@mascotSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText(
          '😭 Validation failed: Image url is not a valid URL',
        ).should('be.visible');
      });
    });

    it('accepts a valid image URL', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('mascotSectionForm').as('mascotSectionForm');

        cy.get('@mascotSectionForm').findByText('Mascot').click();
        cy.get('@mascotSectionForm')
          .get('#settings_mascot_image_url')
          .clear()
          .type('https://example.com/image.png');

        cy.get('@mascotSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@mascotSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

        // Page reloaded so need to get a new reference to the form.
        cy.get('#new_settings_mascot').as('mascotSectionForm');
        cy.get('#settings_mascot_image_url').should(
          'have.value',
          'https://example.com/image.png',
        );
      });
    });
  });
});
