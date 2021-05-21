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
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_community').as('communitySectionForm');

        cy.get('@communitySectionForm').findByText('Community Content').click();
        cy.get('@communitySectionForm')
          .get('#settings_community_community_emoji')
          .clear()
          .type('X');

        cy.get('@communitySectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@communitySectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText(
          '😭 Validation failed: Community emoji contains non-emoji characters or invalid emoji',
        ).should('be.visible');
      });
    });

    it('accepts a valid emoji', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_community').as('communitySectionForm');

        cy.get('@communitySectionForm').findByText('Community Content').click();
        cy.get('@communitySectionForm')
          .get('#settings_community_community_emoji')
          .clear()
          .type('🌱');

        cy.get('@communitySectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@communitySectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

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
