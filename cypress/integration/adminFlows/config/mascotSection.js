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
          .findByLabelText('Mascot Image URL')
          .clear()
          .type('notanimage');

        cy.get('@mascotSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@mascotSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText(
          '😭 Validation failed: Mascot image url is not a valid URL',
        ).should('be.visible');
      });
    });

    it('accepts a valid image URL', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('mascotSectionForm').as('mascotSectionForm');

        cy.get('@mascotSectionForm').findByText('Mascot').click();
        cy.get('@mascotSectionForm')
          .findByLabelText('Mascot Image URL')
          .clear()
          .type('https://example.com/image.png');

        cy.get('@mascotSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@mascotSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText('Successfully updated settings.').should('be.visible');

        // Page reloaded so need to get a new reference to the form.
        cy.findByTestId('mascotSectionForm').as('mascotSectionForm');
        cy.findByLabelText('Mascot Image URL').should(
          'have.value',
          'https://example.com/image.png',
        );
      });
    });
  });
});
