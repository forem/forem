describe('Community Content Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('community emoji setting', () => {
    it('rejects invalid input (no emoji)', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_community').as('communitySectionForm');

        cy.get('@communitySectionForm').findByText('Community Content').click();
        cy.get('@communitySectionForm')
          .get('#settings_community_community_emoji')
          .clear()
          .type('X');

        cy.get('@communitySectionForm').findByText('Update Settings').click();

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Validation failed: Community emoji contains non-emoji characters or invalid emoji',
          );
        });

        cy.url().should('contains', '/admin/customization/config');
      });
    });

    it('accepts a valid emoji', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_community').as('communitySectionForm');

        cy.get('@communitySectionForm').findByText('Community Content').click();
        cy.get('@communitySectionForm')
          .get('#settings_community_community_emoji')
          .clear()
          .type('🌱');

        cy.get('@communitySectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Successfully updated settings.',
          );
        });

        // Page reloaded so need to get a new reference to the form.
        cy.get('#new_settings_community').as('communitySectionForm');
        cy.get('#settings_community_community_emoji').should(
          'have.value',
          '🌱',
        );
      });
    });
  });
});
