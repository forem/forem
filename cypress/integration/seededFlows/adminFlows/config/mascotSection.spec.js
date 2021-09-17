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
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('mascotSectionForm').as('mascotSectionForm');

        cy.get('@mascotSectionForm').findByText('Mascot').click();
        cy.get('@mascotSectionForm')
          .findByLabelText('Mascot Image URL')
          .clear()
          .type('notanimage');

        cy.get('@mascotSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Validation failed: Mascot image url is not a valid URL',
          );
        });
      });
    });

    it('accepts a valid image URL', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('mascotSectionForm').as('mascotSectionForm');

        cy.get('@mascotSectionForm').findByText('Mascot').click();
        cy.get('@mascotSectionForm')
          .findByLabelText('Mascot Image URL')
          .clear()
          .type('https://example.com/image.png');

        cy.get('@mascotSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Successfully updated settings.',
          );
        });

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
